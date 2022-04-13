/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity ^0.8.11;

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)
/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
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
}

// 
interface IWineEnums {

    enum BottleSize {NotSelected, Piccolo, Demi, Standard, Magnum, DoubleMagnum, Jeroboam, Rehoboam, Imperial, Salmanazar, Balthazar, Nebuchadnezzar, Solomon}
    enum WineType {NotSelected, Red, White, Rose, Sparkling, Dessert, Fortified}

    struct Wine {
        uint256 tokenId;
        address brand;
        string title;
        WineType wineType;
        BottleSize bottleSize;
        string classification;
        string vintage;
        string country;
        string region;
        string composition;
        string volume;
        //https://www.winespectator.com/articles/what-do-ph-and-ta-numbers-mean-to-a-wine-5035
        uint256 totalAcidity18;
        uint256 ph18;
        uint256 alcohol18;
        uint256 timeInBarrelSec;
        string condition;
        string label;
        string imageUrl;
        uint256 datePublished;
    }

    struct Location {
        string addressLine1;
        string addressLine2;
        string city;
        string province;
        string countryCode;
        string postalCode;
        uint256 lng;
        uint256 lat;
    }

    //enum Currency {EUR, USD, ETH, MATIC}
}

// 
interface IWineCellar {

    function owner() external view returns (address);

    function getCurrency() external view returns (string memory);

    function getNumberOfBottles(uint256 tokenId_, address owner_) external view returns (uint256);

    function depositBottles(address owner_, uint256 tokenId_, uint256 amount_) external;

    function transferBottles(address from_, address to_, uint256 tokenId_, uint256 amount_) external;

    function removeBottles(address owner_, uint256 tokenId_, uint256 amount_) external;
}

// 
interface IWineToken {

    function owner() external view returns (address);

    function getBrand(uint256 tokenId_) external returns (address);

    function mint(address to_, uint256 tokenId_, uint256 amount_, bytes memory data_) external;

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, uint256 amount_, bytes memory data_) external;

    function registerWine() external returns (uint256);

    function unregisterWine(uint256 tokenId_) external;

    function isRegisteredMarketplace(address marketplace_) external view returns (bool);

}

// 
interface IWineMarketplace {
    function placeAskMarketOrder(address cellar_, uint256 tokenId_, uint256 numberOfBottles_, uint256 pricePerBottleUSD18_, string memory currency_) external;

    function placeBidMarketOrder(uint256 tokenId_, uint256 numberOfBottles_, uint256 maxPricePerBottleUSD18_, string memory currency_) external payable;
}

// 
contract WineBrand is IWineEnums, ERC1155Holder, Ownable {

    string private _displayName;

    string private _url;

    string private _country;

    Location private _location;

    string private _currency = "USD";

    address _wineToken = address(0);

    address _marketplace = address(0);

    // Mapping wine token ID to its additional information
    // Token ID => Wine Data
    mapping(uint256 => Wine) private _wineData;

    // Registered cellars
    mapping(address => bool) private _cellars;

    constructor (address wineToken_){
        _wineToken = wineToken_;
    }

    function getDisplayName() external view returns (string memory) {
        return _displayName;
    }

    function setDisplayName(string memory displayName_) external onlyOwner {
        _displayName = displayName_;
    }

    function getUrl() external view returns (string memory) {
        return _url;
    }

    function setUrl(string memory url_) external onlyOwner {
        _url = url_;
    }

    function getCountry() external view returns (string memory) {
        return _country;
    }

    function setCountry(string memory country_) external onlyOwner {
        _country = country_;
    }

    function getCurrency() external view returns (string memory) {
        return _currency;
    }

    function setCurrency(string memory currency_) external onlyOwner {
        _currency = currency_;
    }

    function getLocation() external returns (string memory, string memory, string memory, string memory, string memory, string memory, uint256, uint256) {
        return (_location.addressLine1, _location.addressLine2, _location.city, _location.province, _location.countryCode, _location.postalCode, _location.lng, _location.lat);
    }

    function setLocation(Location memory location_) external onlyOwner {
        _location = location_;
    }

    function setMarketplace(address marketplace_) external onlyOwner {
        _marketplace = marketplace_;
    }

    function getMarketplace() external view returns (address){
        return _marketplace;
    }

    function setWineToken(address wineToken_) external {
        require(_msgSender() == IWineToken(_wineToken).owner(), "WineBrand: only WineToken owner can update it");

        _wineToken = wineToken_;
    }

    function getWineToken() external view returns (address) {
        return _wineToken;
    }

    function registerCellar(address cellar_) external onlyOwner{
        require(owner() == IWineCellar(cellar_).owner(), "WineBrand: the cellar must belong to this brand owner");

        // todo check it implements cellar interface

        _cellars[cellar_] = true;
    }

    function unregisterCellar(address cellar_) external onlyOwner{
        _cellars[cellar_] = false;
    }

    function isRegisteredCellar(address cellar_) external view returns (bool){
        return _cellars[cellar_];
    }

    function registerWine(Wine memory wine_) external onlyOwner returns (uint256) {
        uint256 tokenId = IWineToken(_wineToken).registerWine();
        wine_.tokenId = tokenId;
        _wineData[tokenId] = wine_;
        return tokenId;
    }

    function updateWine(Wine memory wine_) external onlyOwner {
        require(_wineData[wine_.tokenId].tokenId > 0, "WineBrand: this wine is not registered");

        _wineData[wine_.tokenId] = wine_;
    }

    function getWine(uint256 tokenId_) external returns (Wine memory){
        return _wineData[tokenId_];
    }

    function unregisterWine(uint256 tokenId_) external onlyOwner {
        if (_wineData[tokenId_].tokenId > 0) {
            delete _wineData[tokenId_];

            IWineToken(_wineToken).unregisterWine(tokenId_);
        }
    }

    function mint(address cellar_, uint256 tokenId_, uint256 amount_, bytes memory data_) public onlyOwner {
        require(_wineData[tokenId_].tokenId == tokenId_, "WineBrand: this token must be registered by this brand");
        require(_cellars[cellar_] == true, "WineBrand: this cellar must be registered by this brand");

        IWineToken(_wineToken).mint(address(this), tokenId_, amount_, data_);
        IWineCellar(cellar_).depositBottles(address(this), tokenId_, amount_);
    }

    //todo think about providing marketplace as a parameter
    function ask(address cellar_, uint256 tokenId_, uint256 amount_, uint256 pricePerBottle18_) public onlyOwner {
        require(IWineToken(_wineToken).isRegisteredMarketplace(_marketplace) == true, "WineBrand: this marketplace is not registered with WineToken");
        require(_cellars[cellar_] == true, "WineBrand: you need to register this cellar with your brand first");

        IWineMarketplace(_marketplace).placeAskMarketOrder(cellar_, tokenId_, amount_, pricePerBottle18_, _currency);
    }

    function owner() public view override (Ownable) returns (address) {
        return super.owner();
    }

}