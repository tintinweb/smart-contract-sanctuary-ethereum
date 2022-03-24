// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWeb3DAOCN.sol";
import "./interfaces/IBuyNFT.sol";
import "./interfaces/IDaoVault.sol";

/**
 * @title [email protected] NFT销售合约
 * @notice 实现功能:
 *         1. 本合约由Owner权限调用,在部署之后应转移给DaoTreasury合约
 *         2. DaoTreasury合约具有多签功能,可以设置NFT价格
 */
contract BuyNFT is Ownable, IBuyNFT {
    using Address for address;
    /// @dev NFT合约地址
    address public immutable override WEB3DAONFT;
    /// @dev WETH合约地址
    address public immutable override WETH;
    /// @dev DaoVault
    address public override DaoVault;
    /// @dev NFT 价格
    uint256 public override price = 0.025 ether;
    /// @dev NFT数量限制
    uint256 public override maxTotalSupply;

    /**
     * @dev 构造函数
     * @param _WEB3DAONFT NFT合约地址
     * @param _DaoVault DaoVault合约地址
     * @param _WETH WETH合约地址
     */
    constructor(
        address _WEB3DAONFT,
        address _DaoVault,
        address _WETH
    ) {
        WEB3DAONFT = _WEB3DAONFT;
        DaoVault = _DaoVault;
        WETH = _WETH;
    }

    /// @dev See {IBuyNFT-buy}.
    function buy(address to) public override {
        // 发送weth到DaoVault
        WETH.functionCall(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                _msgSender(),
                DaoVault,
                price
            )
        );
        // 存款
        IDaoVault(DaoVault).deposit(price);
        // 铸造nft
        IWeb3DAOCN(WEB3DAONFT).mint(to);
        // 确认总供应量小于最大供应量
        require(
            IWeb3DAOCN(WEB3DAONFT).totalSupply() <= maxTotalSupply,
            "BuyNFT: over max totalSupply"
        );
        emit Buy(to);
    }

    /// @dev See {IBuyNFT-setMaxTotalSupply}.
    function setMaxTotalSupply(uint256 _maxTotalSupply)
        public
        override
        onlyOwner
    {
        maxTotalSupply = _maxTotalSupply;
        emit SetMaxTotalSupply(_maxTotalSupply);
    }

    /// @dev See {IBuyNFT-setPrice}.
    function setPrice(uint256 _price) public override onlyOwner {
        price = _price;
        emit SetPrice(_price);
    }

    /// @dev See {IBuyNFT-setDaoVault}.
    function setDaoVault(address _DaoVault) public override onlyOwner {
        DaoVault = _DaoVault;
        emit SetDaoVault(_DaoVault);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWeb3DAOCN {
    /// @dev event attrTransferAllow
    event AttrTransferAllow(uint256 attrId, bool allow);

    function totalSupply() external view returns (uint256);

    /// @dev return Attr transfer is allow by attrId
    function attrTransferAllow(uint256 attrId) external view returns (bool);

    /// @dev mint NFT token
    function mint(address to) external;

    /// @dev set attr transfer is allow by attrId
    function setAttrTransferAllow(uint256 attrId, bool allow) external;

    /// @dev create attrId
    function create(
        uint256 _attrId,
        string memory _name,
        string memory _symbol,
        uint8 _decimal,
        string memory _uri
    ) external;

    /// @dev [Batched] version of {create}.
    function createBatch(
        uint256[] calldata attrIds,
        string[] calldata names,
        string[] calldata symbols,
        uint8[] memory decimals,
        string[] calldata uris
    ) external;

    /// @dev Mint `amount` value of attribute type `attrId` to `tokenId`.
    function mint(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) external;

    /// @dev [Batched] version of {mint}.
    function mintBatch(
        uint256 tokenId,
        uint256[] memory attrIds,
        uint256[] memory amounts
    ) external;

    /// @dev Destroys `amount` values of attribute type `attrId` from `tokenId`
    function burn(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) external;

    /// @dev [Batched] version of {burn}.
    function burnBatch(
        uint256 tokenId,
        uint256[] memory attrIds,
        uint256[] memory amounts
    ) external;

    /// @dev Sets a new URI for all attribute types
    function setURI(string memory newuri) external;

    /// @dev Base URI for computing {tokenURI}.
    function setBaseURI(string memory newuri) external;

    /// @dev permit
    function permit(
        uint256 from,
        uint256 to,
        uint256 attrId,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBuyNFT {
    /// @dev 购买事件
    event Buy(address to);

    /// @dev 设置NFT价格事件
    event SetPrice(uint256 _price);

    /// @dev 设置DaoVault
    event SetDaoVault(address _DaoVault);

    /// @dev event set max totalSupply
    event SetMaxTotalSupply(uint256 _maxTotalSupply);

    /// @dev NFT合约地址
    function WEB3DAONFT() external view returns (address);

    /// @dev WETH合约地址
    function WETH() external view returns (address);

    /// @dev DaoVault
    function DaoVault() external view returns (address);

    /// @dev NFT 价格
    function price() external view returns (uint256);

    /// @dev NFT数量限制
    function maxTotalSupply() external view returns (uint256);

    /// @dev set nft max totalSupply
    function setMaxTotalSupply(uint256 _maxTotalSupply) external;

    /**
     * @dev 购买NFT
     * @param to 接收NFT的地址
     */
    function buy(address to) external;

    /**
     * @dev 设置NFT价格
     * @param _price NFT价格
     * @notice 仅限owner调用
     */
    function setPrice(uint256 _price) external;

    /**
     * @dev 设置DaoVault合约地址
     * @param _DaoVault 新合约地址
     * @notice 仅限owner调用
     */
    function setDaoVault(address _DaoVault) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDaoVault {
    event Deposit(uint256 amount, uint256 reserve);

    event Withdraw(uint256 amount, uint256 reserve);

    event UpdateReserve(uint256 reserve);

    /// @dev WETH合约地址
    function WETH() external view returns (address);

    /// @dev 储备量balance
    function reserve() external view returns (uint256);

    /**
     * @dev 存款方法
     * @param amount weth存款数量
     * @notice 需要当前合约的weth余额大于储备量
     */
    function deposit(uint256 amount) external;

    /**
     * @dev 取款方法
     * @param amount weth取款数量
     * @param to weth接收地址
     * @notice 仅限owner调用
     */
    function withdraw(uint256 amount, address to) external;

    /**
     * @dev 更新储备量
     * @notice 仅限owner调用
     */
    function updateReserve() external;
}

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