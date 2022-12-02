/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function balanceOf(address account) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

abstract contract OwnerOperator is Ownable {
    mapping(address => bool) public operators;

    constructor() Ownable() {}

    modifier operatorOrOwner() {
        require(
            operators[msg.sender] || owner() == msg.sender,
            "OwnerOperator: !operator, !owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "OwnerOperator: !operator");
        _;
    }

    function addOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = true;
    }

    function removeOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = false;
    }
}

contract MarketPlace is OwnerOperator {
    struct SellItem {
        uint256 tokenId;
        uint256 amountToken;
        uint256 sellAt;
        address seller;
    }

    struct Order {
        uint256 tokenId;
        uint256 amountToken;
        uint256 orderAt;
        TypeOrder typeOrder;
    }

    enum TypeOrder {
        BUY,
        SELL
    }

    address public erc20Address;
    address public erc721Address;

    SellItem[] listTokenSell;
    mapping(uint256 => uint256) public indexTokenByListSell;

    mapping(address => Order[]) public historyOrders;

    event Sell(uint256 nftId, uint256 nftPrice, uint256 date, address owner);
    event Buy(
        uint256 nftId,
        uint256 nftPrice,
        address from,
        address to,
        uint256 date
    );
    event CancelSell(uint256 nftId, address owner, uint256 date);

    function setERC20Address(address _address) external onlyOwner {
        erc20Address = _address;
    }

    function setERC721Address(address _address) external onlyOwner {
        erc721Address = _address;
    }

    function getListTokenSell() external view returns (SellItem[] memory) {
        return listTokenSell;
    }

    function getListOrder(address _address)
        external
        view
        returns (Order[] memory)
    {
        return historyOrders[_address];
    }

    function sell(uint256 tokenId, uint256 amoutToken) external {
        IERC721 erc721Token = IERC721(erc721Address);
        require(
            erc721Token.ownerOf(tokenId) == msg.sender,
            "You are not allower"
        );
        require(
            erc721Token.getApproved(tokenId) == address(this),
            "Allowance insuffice"
        );

        erc721Token.transferFrom(msg.sender, address(this), tokenId);

        listTokenSell.push(
            SellItem(tokenId, amoutToken, block.timestamp, msg.sender)
        );

        indexTokenByListSell[tokenId] = listTokenSell.length - 1;

        historyOrders[msg.sender].push(
            Order(tokenId, amoutToken, block.timestamp, TypeOrder.BUY)
        );

        emit Sell(tokenId, amoutToken, block.timestamp, msg.sender);
    }

    function cancelSell(uint256 tokenId) external {
        IERC721 erc721Token = IERC721(erc721Address);
        require(
            listTokenSell[indexTokenByListSell[tokenId]].seller == msg.sender,
            "You are not allower"
        );
        erc721Token.transferFrom(address(this), msg.sender, tokenId);

        delete listTokenSell[indexTokenByListSell[tokenId]];
        delete indexTokenByListSell[tokenId];
        emit CancelSell(tokenId, msg.sender, block.timestamp);
    }

    function buy(uint256 tokenId, uint256 amountToken) external {
        IERC721 erc721Token = IERC721(erc721Address);
        IERC20 erc20Token = IERC20(erc20Address);
        require(
            erc20Token.balanceOf(msg.sender) >= amountToken,
            "Insuffice balance"
        );
        require(
            erc20Token.allowance(msg.sender, address(this)) >= amountToken,
            "Allowance insuffice"
        );

        require(
            listTokenSell[indexTokenByListSell[tokenId]].seller != msg.sender,
            "Buy by current owner"
        );
        erc20Token.transferFrom(
            msg.sender,
            listTokenSell[indexTokenByListSell[tokenId]].seller,
            amountToken
        );

        erc721Token.transferFrom(address(this), msg.sender, tokenId);

        historyOrders[msg.sender].push(
            Order(tokenId, amountToken, block.timestamp, TypeOrder.SELL)
        );

        emit Buy(
            tokenId,
            amountToken,
            listTokenSell[indexTokenByListSell[tokenId]].seller,
            msg.sender,
            block.timestamp
        );

        delete listTokenSell[indexTokenByListSell[tokenId]];
        delete indexTokenByListSell[tokenId];
    }
}