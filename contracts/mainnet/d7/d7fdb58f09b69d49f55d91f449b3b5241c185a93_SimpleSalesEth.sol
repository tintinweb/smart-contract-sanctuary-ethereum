/**
 *Submitted for verification at Etherscan.io on 2022-06-22
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/SimpleSalesEth.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract SimpleSalesEth is Ownable {

    mapping(address => mapping(uint256 => Sale)) public sales; // map token address and token id to sales
    mapping(address => bool) public sellers; // Only authorized sellers can make sales
    mapping(address => uint256) public failedTransferCredits;

    //Each sale is unique to each NFT (contract + id pairing).
    struct Sale {
        address nftSeller;
        address erc20Token; // Sale can be in any ERC20 token or in ETH. If erc20Token is address(0), it means that auction is in ETH
        uint256 price;
    }

    /* ========== EVENTS ========== */
    
    event SaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint256 price
    );

    event SaleWithdrawn(
        address nftContractAddress,
        uint256 tokenId
    );

    event SaleCompleted(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftBuyer,
        address erc20Token,
        uint256 price
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address _seller) {
        sellers[_seller] = true;
    }

    /* ========== CREATE SALE ========== */

    function createSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _price
    )
        external
    {
        require(sellers[msg.sender], "Unauthorized");
        require(_price > 0, "Price cannot be 0");

        sales[_nftContractAddress][_tokenId].price = _price;
        sales[_nftContractAddress][_tokenId].nftSeller = msg.sender;
        sales[_nftContractAddress][_tokenId].erc20Token = _erc20Token;
        
        emit SaleCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _price
        );
    }

    /* ========== WITHDRAW SALE ========== */

    function withdrawSale(
        address _nftContractAddress,
        uint256 _tokenId
    )
        external
    {
        require(msg.sender == sales[_nftContractAddress][_tokenId].nftSeller, "Not seller");

        delete sales[_nftContractAddress][_tokenId];
        
        emit SaleWithdrawn(
            _nftContractAddress,
            _tokenId
        );
    }

    /* ========== MAKE BID ========== */

    function buy(
        address _nftContractAddress,
        uint256 _tokenId
    )
        external
        payable
    {
        Sale memory sale = sales[_nftContractAddress][_tokenId];

        require(msg.sender != sale.nftSeller, "Owner cannot buy own NFT");

        if (sale.erc20Token != address(0)) { // Check if sale is in ERC20 or in native currency

            require(msg.value == 0, "Payment not accepted");

            IERC20(sale.erc20Token).transferFrom(
                msg.sender,
                sale.nftSeller,
                sale.price
            );

        } else {
            require(msg.value >= sale.price, "Payment not accepted");

            (bool success, ) = payable(sale.nftSeller).call{
                value: msg.value,
                gas: 21000
            }("");
            // if eth transfer fails, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[sale.nftSeller] =
                    failedTransferCredits[sale.nftSeller] +
                    msg.value;
            }
        }
        
        delete sales[_nftContractAddress][_tokenId];

        emit SaleCompleted(
            _nftContractAddress,
            _tokenId,
            sale.nftSeller,
            msg.sender,
            sale.erc20Token,
            sale.price
        );
    }


    /* ========== WITHDRWA FAILED CREDITS ========== */

    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call{
            value: amount,
            gas: 21000
        }("");
        require(successfulWithdraw, "withdraw failed");
    }
    
    /* ========== SETTINGS ========== */

    function addSeller(address _seller) external onlyOwner {
        sellers[_seller] = true;
    }

    function removeSeller(address _seller) external onlyOwner {
        sellers[_seller] = false;
    }
}