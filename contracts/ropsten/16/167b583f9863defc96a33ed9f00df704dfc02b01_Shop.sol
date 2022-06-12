/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// Sources flattened with hardhat v2.9.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/Shop.sol

pragma solidity ^0.8.0;


contract Shop is Ownable {
    event BuyNFT(address indexed nft, address indexed buyer, uint price, uint num, uint timestamp);

    enum Cat {
        None, // 0
        SnoopDogg, // 1
        Urban,
        Rothschild,
        SakuragiHanamichi,
        MasterShifu,
        Spock
    }

    bool public saleIsActive = true;
    IERC20 private usdt;

    mapping(Cat => address) public catAddress;
    mapping(Cat => uint) public catPrice;
    mapping(Cat => uint) public catCounts;
    mapping(Cat => uint) public catMaxSupply;

    constructor() {
        catPrice[Cat.SnoopDogg] = 4888 * 10 ** 18;
        catPrice[Cat.Urban] = 2888 * 10 ** 18;
        catPrice[Cat.Rothschild] = 288 * 10 ** 18;
        catPrice[Cat.SakuragiHanamichi] = 4888 * 10 ** 18;
        catPrice[Cat.MasterShifu] = 2888 * 10 ** 18;
        catPrice[Cat.Spock] = 288 * 10 ** 18;

        catMaxSupply[Cat.SnoopDogg] = 100;
        catMaxSupply[Cat.Urban] = 200;
        catMaxSupply[Cat.Rothschild] = 500;
        catMaxSupply[Cat.SakuragiHanamichi] = 100;
        catMaxSupply[Cat.MasterShifu] = 200;
        catMaxSupply[Cat.Spock] = 500;
    }

    function OpenSale() external onlyOwner {
        saleIsActive = true;
    }

    function CloseSale() external onlyOwner {
        saleIsActive = false;
    }

    function setCatAddress(Cat _type, address _addr) external onlyOwner {
        require(_type >= Cat.SnoopDogg && _type <= Cat.Spock, "Invalid cat type");
        require(_addr != address(0), "Zero address");
        catAddress[_type] = _addr;
    }

    function setUsdtAddress(address _usdt) public onlyOwner {
        usdt = IERC20(_usdt);
    }

    // buy NFT
    function buy(Cat _type, uint num) external payable {
        require(num > 0, "Number of tokens can not be less than or equal to 0");
        require(_type >= Cat.SnoopDogg && _type <= Cat.Spock, "Wrong cat type");
        require(catCounts[_type] + num <= catMaxSupply[_type], "Purchase would exceed max supply");

        address cat  = catAddress[_type];
        uint price = catPrice[_type];
        uint amount = price * num;

        bool ok = usdt.approve(address(this), amount);
        require(ok, "ERC20: approve failed");
        ok = usdt.transferFrom(msg.sender, address(this), amount);
        require(ok, "ERC20: transferFrom failed");

        bytes memory data = abi.encodeWithSignature("mint(address,uint256)", msg.sender, num);
        (bool success, ) = cat.call(data);
        require(success, "ERC721: mint failed");
        catCounts[_type] += num;

        emit BuyNFT(cat, msg.sender, price, num, block.timestamp);
    }

    // withdraw tokens
    function withdraw() external onlyOwner {
        // withdraw usdt
        uint balanceUSDT = usdt.balanceOf(address(this));
        if (balanceUSDT > 0) {
            bool success = usdt.transfer(msg.sender, balanceUSDT);
            require(success, "ERC20: transfer");
        }

        // withdraw native token
        uint balanceNative = address(this).balance;
        if (balanceNative > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }


    receive() external payable{}
}