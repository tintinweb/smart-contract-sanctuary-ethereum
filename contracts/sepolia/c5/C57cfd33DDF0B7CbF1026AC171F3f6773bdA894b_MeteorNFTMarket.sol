/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/xurisheng/projects/games/跑酷/code/meteornrun-contracts/contracts/MeteorNFTMarket.sol
// flattened :  Wednesday, 31-May-23 10:09:50 UTC
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IMeteorNFT {
    function safeMint(address to) external;

    function currentTokenId() external view returns (uint256);
}

contract MeteorNFTMarket is Context, Ownable {
    address public treasury;
    address public nft;
    address public USDT;

    struct Sale {
        uint8 nftType;
        uint256 price;
        uint256 total;
    }

    // nftType => sale
    mapping(uint8 => Sale) public sales;

    event Bought(address indexed buyer, uint8 nftType, uint256 tokenId);

    constructor(address _treasury, address _nft, address _usdt) {
        treasury = _treasury;
        nft = _nft; 
        USDT = _usdt;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setSale(
        uint8 nftType,
        uint256 price,
        uint256 total
    ) public onlyOwner {
        Sale storage sale = sales[nftType];
        sale.nftType = nftType;
        sale.price = price;
        sale.total = total;
    }

    function buy(uint8 nftType) external {
        Sale storage sale = sales[nftType];
        require(sale.total > 0, "MeteorNFTMarket: sold out");
        address sender = _msgSender();
        if (sale.price > 0) {
            IERC20(USDT).transferFrom(sender, treasury, sale.price);
        }
        sale.total--;
        _mint(sender, nftType);
    }

    function _mint(address recipient, uint8 nftType) internal {
        IMeteorNFT(nft).safeMint(recipient);
        uint256 tokenId = IMeteorNFT(nft).currentTokenId() - 1;
        emit Bought(recipient, nftType, tokenId);
    }

    function batchMint(
        address recipient,
        uint256 total,
        uint8 nftType
    ) external onlyOwner {
        for (uint i = 0; i < total; i++) {
            _mint(recipient, nftType);
        }
    }
}