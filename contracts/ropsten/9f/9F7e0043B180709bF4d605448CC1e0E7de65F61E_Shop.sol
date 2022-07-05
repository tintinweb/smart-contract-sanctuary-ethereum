/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

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


// File @openzeppelin/contracts/utils/introspection/[email protected]
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


// File @openzeppelin/contracts/token/ERC721/[email protected]
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File contracts/Shop.sol
pragma solidity ^0.8.0;



contract Shop is Ownable {
    event BuyItem(address indexed nft, address indexed buyer, uint price, uint num, uint timestamp);

    enum Cat {
        None, // 0
        SnoopDogg, // 1
        Urban,
        Rothschild,
        SakuragiHanamichi,
        MasterShifu,
        Spock,
        ChanKwongYan // 7
    }

    struct Record {
        address nft;
        address buyer;
        uint price;
        uint num;
        uint timestamp;
    }

    bool public saleIsActive = false;
    uint private totalUsdt;
    IERC20 public usdt;

    mapping(Cat => address) public catAddress;
    mapping(Cat => uint) public soldCatCounts;
    mapping(Cat => uint) public catPrice;
    mapping(Cat => uint) public catMaxSupply;
    mapping(address => mapping(Cat => uint)) public userCatCounts;

    mapping(address => Record[]) buyRecords;

    modifier ValidAddress(address _addr) {
        require(_addr != address(0), "Zero address");
        _;
    }

    modifier ValidType(Cat _type) {
        require(_type >= Cat.SnoopDogg && _type <= Cat.ChanKwongYan, "Invalid cat type");
        _;
    }

    constructor() {
        // supply
        catMaxSupply[Cat.SnoopDogg] = 100;
        catMaxSupply[Cat.Urban] = 200;
        catMaxSupply[Cat.Rothschild] = 500;
        catMaxSupply[Cat.SakuragiHanamichi] = 100;
        catMaxSupply[Cat.MasterShifu] = 200;
        catMaxSupply[Cat.Spock] = 500;
        catMaxSupply[Cat.ChanKwongYan] = 100000;
        // price
        catPrice[Cat.SnoopDogg] = 4888 * 10 ** 18;
        catPrice[Cat.Urban] = 2888 * 10 ** 18;
        catPrice[Cat.Rothschild] = 288 * 10 ** 18;
        catPrice[Cat.SakuragiHanamichi] = 4888 * 10 ** 18;
        catPrice[Cat.MasterShifu] = 2888 * 10 ** 18;
        catPrice[Cat.Spock] = 288 * 10 ** 18;
        catPrice[Cat.ChanKwongYan] = 0.05 * 10 ** 18;
    }

    // sold counts
    function getSoldCatCounts() external view returns(uint[7] memory) {
        uint[7] memory counts = [
            soldCatCounts[Cat.SnoopDogg],
            soldCatCounts[Cat.Urban],
            soldCatCounts[Cat.Rothschild],
            soldCatCounts[Cat.SakuragiHanamichi],
            soldCatCounts[Cat.MasterShifu],
            soldCatCounts[Cat.Spock],
            soldCatCounts[Cat.ChanKwongYan]
        ];

        return counts;
    }

    // user balance
    function getUserCatCounts() external view returns(uint[7] memory) {
        uint b1 = IERC721(catAddress[Cat.SnoopDogg]).balanceOf(address(msg.sender));
        uint b2 = IERC721(catAddress[Cat.Urban]).balanceOf(address(msg.sender));
        uint b3 = IERC721(catAddress[Cat.Rothschild]).balanceOf(address(msg.sender));
        uint b4 = IERC721(catAddress[Cat.SakuragiHanamichi]).balanceOf(address(msg.sender));
        uint b5 = IERC721(catAddress[Cat.MasterShifu]).balanceOf(address(msg.sender));
        uint b6 = IERC721(catAddress[Cat.Spock]).balanceOf(address(msg.sender));
        uint b7 = IERC721(catAddress[Cat.ChanKwongYan]).balanceOf(address(msg.sender));

        uint[7] memory counts = [b1, b2, b3, b4, b5, b6, b7];

        return counts;
    }

    // open sale
    function openSale() external onlyOwner {
        saleIsActive = true;
    }

    // close sale
    function closeSale() external onlyOwner {
        saleIsActive = false;
    }

    // set cat price
    function setCatPrice(Cat _type, uint _price) external onlyOwner ValidType(_type) {
        require(_price > 0, "Price must be greater than 0");
        catPrice[_type] = _price;
    }

    // set cat address
    function setCatAddress(Cat _type, address _addr) external onlyOwner ValidType(_type) ValidAddress(_addr) {
        catAddress[_type] = _addr;
    }

    // set usdt address
    function setUsdtAddress(address _addr) public onlyOwner ValidAddress(_addr) {
        usdt = IERC20(_addr);
    }

    // buy NFT
    function buy(Cat _type, uint num) external payable ValidType(_type) {
        require(saleIsActive, "Sales not start");
        require(num > 0, "Number of tokens can not be less than or equal to 0");

        address cat  = catAddress[_type];
        uint price = catPrice[_type];
        uint amount = price * num;
        if (_type == Cat.ChanKwongYan) {
            require(msg.value >= amount);
        } else {
            bool ok = usdt.transferFrom(msg.sender, address(this), amount);
            require(ok, "ERC20: transferFrom failed");
        }

        // mint
        bytes memory data = abi.encodeWithSignature("mint(address,uint256)", msg.sender, num);
        (bool success, ) = cat.call(data);
        require(success, "ERC721: mint failed");

        buyRecords[msg.sender].push(Record({
            nft: cat,
            buyer: msg.sender,
            price: price,
            num: num,
            timestamp: block.timestamp
        }));
        if (_type != Cat.ChanKwongYan) {
            totalUsdt += amount;
        }
        soldCatCounts[_type] += num;
        userCatCounts[msg.sender][_type] += num;

        emit BuyItem(cat, msg.sender, price, num, block.timestamp);
    }

    function income() external view returns(uint) {
        return totalUsdt;
    }

    function records() external view returns(Record[] memory) {
        return buyRecords[msg.sender];
    }

    // withdraw tokens
    function withdraw() external onlyOwner {
        uint balanceUSDT = usdt.balanceOf(address(this));
        if (balanceUSDT > 0) {
            bool success = usdt.transfer(msg.sender, balanceUSDT);
            require(success, "ERC20: transfer");
        }

        uint balanceNative = address(this).balance;
        if (balanceNative > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    receive() external payable{}
}