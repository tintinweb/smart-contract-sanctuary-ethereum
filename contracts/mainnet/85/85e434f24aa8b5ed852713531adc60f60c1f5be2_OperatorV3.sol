/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface TokenMover {
    function transferERC20(address currency, address from, address to, uint256 amount) external;
    function transferERC721(address currency, address from, address to, uint256 tokenId) external;
}

interface NFTToken {
    function mintForSomeoneAndBuy(
        uint256 tokenId,
        address[] calldata creators,
        uint256[] calldata royaltyPercent,
        address buyer
    ) external;
}

interface FeeManager {
    function getPartnerFee(address partner) external view returns (uint256);
}

interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

interface IERCMultiRoyalties {
    function royaltyInfoAll(uint256 tokenId, uint256 value) external view returns (address[] memory, uint256[] memory);
}

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

contract OperatorV3 is Ownable {

    TokenMover immutable public tokenMover;
    address private feeManager;
    address private feeRecipient;

    mapping(address => bool) internal _isApp;

    event SaleAwarded(address from, address to, uint256 tokenId);

    constructor(address _feeManager, address _feeRecipient, address _TokenMover) {
        feeManager = _feeManager;
        feeRecipient = _feeRecipient;
        tokenMover = TokenMover(_TokenMover);
    }

    modifier onlyApp() {
        require(_isApp[_msgSender()], "Caller is not the app");
        _;
    }

    function getFeeManager() public view returns(address) {
        return feeManager;
    }

    function getFeeRecipient() public view returns(address) {
        return feeRecipient;
    }

    function isApp(address _app) public view returns(bool) {
        return _isApp[_app];
    }

    function mintAndSell(
        uint256 tokenId,
        address nftContract,
        address[] calldata owners,
        address buyer,
        uint256 price,
        uint256 extraFee,
        uint256[] calldata royaltyPercentages,
        address currency
    ) external onlyApp {
        require(price > 0, "Price should be greater than zero");
        _takeFeeOnMint(owners, royaltyPercentages, buyer, price, extraFee, currency);
        NFTToken(nftContract).mintForSomeoneAndBuy(tokenId, owners, royaltyPercentages, buyer);
        emit SaleAwarded(owners[0], buyer, tokenId);
    }

    function sellItem(
        uint256 tokenId,
        address nftContract,
        address owner,
        address buyer,
        uint256 price,
        uint256 extraFee,
        address currency
    ) external onlyApp {
        require(price > 0, "Price should be greater than zero");
        _takeFee(tokenId, nftContract, owner, buyer, price, extraFee, currency);
        tokenMover.transferERC721(nftContract, owner, buyer, tokenId);
        emit SaleAwarded(owner, buyer, tokenId);
    }

    function _takeFeeOnMint(
        address[] calldata sellers,
        uint256[] calldata percentages,
        address buyer,
        uint256 price,
        uint256 extraFee,
        address currency
    ) internal {

        uint256 commission = FeeManager(feeManager).getPartnerFee(sellers[0]);
        uint256 platformFee = (price*commission)/10000 + extraFee;
        uint256 amountForSeller = price - platformFee;

        uint256 total;
        uint256 length = sellers.length;

        for(uint256 i = 0; i < length; i++) {
            total += percentages[i];
        }
        _sendToMany(currency, buyer, sellers, percentages, amountForSeller, total);
        tokenMover.transferERC20(currency, buyer, feeRecipient, platformFee);
    }

    function _sendToMany(address currency, address from, address[] calldata tos, uint256[] calldata percentages, uint256 amount, uint256 total) internal {

        uint256 length = tos.length;
        for(uint256 i = 0; i < length; i++) {
            uint256 amountA = amount*percentages[i]/total;
            tokenMover.transferERC20(currency, from, tos[i], amountA);
        }
    }

    function _takeFee(
        uint256 tokenId,
        address nftContract,
        address seller,
        address buyer,
        uint256 price,
        uint256 extraFee,
        address currency
    ) internal {

        uint256 totalRoyalty;
        if(IERC165(nftContract).supportsInterface(type(IERCMultiRoyalties).interfaceId)) {

            (address[] memory recipients, uint256[] memory amounts) = IERCMultiRoyalties(nftContract).royaltyInfoAll(tokenId, price);
            uint256 length = recipients.length;
            for(uint256 i = 0; i < length; i++) {
                totalRoyalty += amounts[i];
                tokenMover.transferERC20(currency, buyer, recipients[i], amounts[i]);
            }

        } else if(IERC165(nftContract).supportsInterface(type(IERC2981Royalties).interfaceId)) {
            (address recipient, uint256 amount) = IERC2981Royalties(nftContract).royaltyInfo(tokenId, price);

            if(seller != recipient) {
                totalRoyalty = amount;
                tokenMover.transferERC20(currency, buyer, recipient, amount);
            }
        }

        uint256 commission = FeeManager(feeManager).getPartnerFee(seller);
        uint256 platformFee = (price*commission)/10000 + extraFee;
        uint256 amountForSeller = price - platformFee - totalRoyalty;

        tokenMover.transferERC20(currency, buyer, seller, amountForSeller);
        tokenMover.transferERC20(currency, buyer, feeRecipient, platformFee);
    }

    function changeFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function addApp(address _app) external onlyOwner {
        require(!_isApp[_app], "Address already added as app");
        _isApp[_app] = true;
    }

    function removeApp(address _app) external onlyOwner {
        require(_isApp[_app], "Address is not added as app");
        _isApp[_app] = false;
    }
}