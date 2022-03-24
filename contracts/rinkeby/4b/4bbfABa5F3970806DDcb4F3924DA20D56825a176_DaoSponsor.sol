// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EIP3664/interfaces/IERC3664.sol";
import "./interfaces/IWeb3DAOCN.sol";
import "./interfaces/IDaoVault.sol";
import "./interfaces/IDaoTreasury.sol";
import "./interfaces/IDaoSponsor.sol";

/**
 * @title [email protected]赞助商合约
 * @notice 实现功能:
 *         1. 本合约由Owner权限调用,在部署之后应转移给DaoTreasury合约
 *         2. 赞助Dao方法,为tokenId铸造Sponsor值
 *         3. 退出Sponsor值,计算可以取出的ETh数量
 */
contract DaoSponsor is Ownable, IDaoSponsor {
    using Address for address;
    /// @dev NFT合约地址
    address public immutable override WEB3DAONFT;
    /// @dev DaoVault
    address public override DaoVault;
    /// @dev DaoTreasury
    address public override DaoTreasury;
    /// @dev NFT合约中Sponsor attrId
    uint256 public immutable override SPONSOR_ATTR_ID;
    /// @dev 最大借款比例
    uint256 public override maxBorrow = 8000;
    /// @dev 除数
    uint256 public constant override max = 10000;
    /// @dev Sponsor锁仓数据
    mapping(uint256 => LockVault) public _lockVault;
    /// @dev sponsor数组
    uint256[] public sponsors;
    /// @dev sponsor数组索引;
    mapping(uint256 => uint256) public sponsorIndex;

    /**
     * @dev 构造函数
     * @param _WEB3DAONFT NFT合约地址
     * @param _DaoVault DaoVault合约地址
     * @param _DaoTreasury DaoTreasury合约地址
     * @param _SPONSOR_ATTR_ID NFT合约中Sponsor attrId
     */
    constructor(
        address _WEB3DAONFT,
        address _DaoVault,
        address _DaoTreasury,
        uint256 _SPONSOR_ATTR_ID
    ) {
        WEB3DAONFT = _WEB3DAONFT;
        DaoVault = _DaoVault;
        DaoTreasury = _DaoTreasury;
        SPONSOR_ATTR_ID = _SPONSOR_ATTR_ID;
    }

    /// @dev See {IDaoSponsor-lockVault}.
    function lockVault(uint256 tokenId)
        public
        view
        override
        returns (LockVault memory)
    {
        return _lockVault[tokenId];
    }

    /// @dev See {IDaoSponsor-sponsor}.
    function sponsor(uint256 tokenId, uint256 ethAmount)
        public
        override
        onlyOwner
    {
        // NFT合约的 sponsor attr总发行量
        uint256 sponsorTotalSupply = IERC3664(WEB3DAONFT).totalSupply(
            SPONSOR_ATTR_ID
        );
        // DaoVault储备量
        uint256 reserve = IDaoVault(DaoVault).reserve();
        // 初始化sponsor值数量
        uint256 sponsorAmount;
        // 如果sponsor总发行量为0,首次铸造
        if (sponsorTotalSupply == 0) {
            // sponsor值 = 赞助的weth数量
            sponsorAmount = ethAmount;
            // 否则为后续赞助
        } else {
            // sponsor值 = 赞助的weth数量 * sponsor总发行量 / 储备量
            sponsorAmount = (ethAmount * sponsorTotalSupply) / reserve;
        }
        // 锁仓结构体
        LockVault storage la = _lockVault[tokenId];
        // 锁仓数量增加赞数的数量
        la.sponsorAmount += sponsorAmount;
        // 锁仓时间顺延一年
        la.time = block.timestamp + 365 days;
        // 为指定的NFT tokenId铸造sponsor值数量
        IWeb3DAOCN(WEB3DAONFT).mint(tokenId, SPONSOR_ATTR_ID, sponsorAmount);
        // 记录sponsor数组
        if (sponsorIndex[tokenId] == 0) {
            sponsors.push(tokenId);
            sponsorIndex[tokenId] = sponsors.length - 1;
        }
        emit Sponsor(tokenId, ethAmount, sponsorAmount);
    }

    /// @dev See {IDaoSponsor-quit}.
    function quit(uint256 tokenId, uint256 sponsorAmount)
        public
        override
        onlyOwner
        returns (uint256 quitAmount)
    {
        // 锁仓结构体
        LockVault storage lv = _lockVault[tokenId];
        // 确认时间大于1年
        require(block.timestamp >= lv.time, "DaoSponsor: lock time!");
        // 确认有足够的锁仓量
        require(
            lv.sponsorAmount - lv.stakeAmount >= sponsorAmount,
            "DaoSponsor: no enough sponsorAmount!"
        );

        // DaoVault合约的储备量
        uint256 reserve = IDaoVault(DaoVault).reserve();
        // NFT合约的 sponsor attr总发行量
        uint256 sponsorTotalSupply = IERC3664(WEB3DAONFT).totalSupply(
            SPONSOR_ATTR_ID
        );
        // 计算退出的weth数量 = 退出的sponsor值数量 * 储备量 / sponsor总发行量
        quitAmount = (sponsorAmount * reserve) / sponsorTotalSupply;
        // 减少sponsorAmount
        lv.sponsorAmount -= sponsorAmount;
        // 销毁退出的sponsor值数量
        IWeb3DAOCN(WEB3DAONFT).burn(tokenId, SPONSOR_ATTR_ID, sponsorAmount);
        emit Quit(tokenId, sponsorAmount, quitAmount);
    }

    /// @dev See {IDaoSponsor-borrowGas}.
    function borrowGas(uint256 tokenId, uint256 gasAmount)
        public
        override
        onlyOwner
        returns (bool)
    {
        // NFT合约的 sponsor attr总发行量
        uint256 sponsorTotalSupply = IERC3664(WEB3DAONFT).totalSupply(
            SPONSOR_ATTR_ID
        );
        // DaoVault储备量
        uint256 reserve = IDaoVault(DaoVault).reserve();
        // gas和eth兑换比例
        uint256 gasAttrPrice = IDaoTreasury(DaoTreasury).gasAttrPrice();
        // 实例化锁仓结构体
        LockVault storage lv = _lockVault[tokenId];
        // 计算sponsorAmount总价值对应的ethAmount
        uint256 ethAmount = (lv.sponsorAmount * reserve) / sponsorTotalSupply;
        // 确认 已经借出的gas+这次要借出的gas / sponsorAmount总价值对应的ethAmount * 10000 小于最大借出比例
        require(
            ((lv.borrowGasAmount + gasAmount) * 1 ether) /
                (ethAmount * gasAttrPrice) <=
                (maxBorrow * 1 ether) / max,
            "DaoSponsor:more than max borrow"
        );
        // 需要锁定的sponsor数量 = 借出的gas数量 * sponsor总发行量 / (eth储备量 * 10000)
        uint256 stakeAmount = (gasAmount * sponsorTotalSupply) /
            (reserve * gasAttrPrice);
        // 更新锁仓数据
        lv.stakeAmount += stakeAmount;
        lv.borrowGasAmount += gasAmount;
        emit BorrowGas(tokenId, gasAmount, stakeAmount);
        return true;
    }

    /// @dev See {IDaoSponsor-returnGas}.
    function returnGas(uint256 tokenId, uint256 gasAmount)
        public
        override
        onlyOwner
        returns (bool)
    {
        // 实例化锁仓结构体
        LockVault storage lv = _lockVault[tokenId];
        // 确认借出的gas大于等于归还的gas
        require(lv.borrowGasAmount >= gasAmount, "DaoSponsor: gasAmount error");
        // 解锁数量 = 锁定的数量 * 归还数量 * 10000 / 借出的gas
        uint256 unStakeAmount = (lv.stakeAmount * gasAmount) /
            lv.borrowGasAmount;
        // 更新锁仓数据
        lv.stakeAmount -= unStakeAmount;
        lv.borrowGasAmount -= gasAmount;
        emit ReturnGas(tokenId, gasAmount, unStakeAmount);
        return true;
    }

    /// @dev See {IDaoSponsor-setDaoVault}.
    function setDaoVault(address _DaoVault) public override onlyOwner {
        DaoVault = _DaoVault;
        emit SetDaoVault(_DaoVault);
    }

    /// @dev See {IDaoSponsor-setDaoTreasury}.
    function setDaoTreasury(address _DaoTreasury) public override onlyOwner {
        DaoTreasury = _DaoTreasury;
        emit SetDaoTreasury(_DaoTreasury);
    }

    /// @dev See {IDaoSponsor-setMaxBorrow}.
    function setMaxBorrow(uint256 _maxBorrow) public override onlyOwner {
        maxBorrow = _maxBorrow;
        emit SetMaxBorrow(_maxBorrow);
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

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC3664 compliant contract.
 */
interface IERC3664 is IERC165 {
    /**
     * @dev Emitted when new attribute type `attrId` are minted.
     */
    event AttributeCreated(
        uint256 indexed attrId,
        string name,
        string symbol,
        uint8 _decimal,
        string uri
    );

    /**
     * @dev Emitted when `value` of attribute type `attrId` are attached to "to"
     * or removed from `from` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        uint256 indexed from,
        uint256 indexed to,
        uint256 attrId,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events.
     */
    event TransferBatch(
        address indexed operator,
        uint256 indexed from,
        uint256 indexed to,
        uint256[] attrIds,
        uint256[] values
    );

    /**
     * @dev Emitted when  attribute type `attrId` are approved to "to" from `from` by `operator`.
     */
    event AttributeApproval(
        address indexed operator,
        uint256 from,
        uint256 to,
        uint256 attrId,
        uint256 amount
    );

    /**
     * @dev Returns the attribute type `attrId` value owned by `tokenId`.
     */
    function balanceOf(uint256 tokenId, uint256 attrId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the batch of attribute type `attrIds` values owned by `tokenId`.
     */
    function balanceOfBatch(uint256 tokenId, uint256[] calldata attrIds)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns true if `attrId` is approved to token `to` from token `from`.
     */
    function allowance(
        uint256 from,
        uint256 to,
        uint256 attrId
    ) external view returns (uint256);

    /**
     * @dev Returns the amount of attribute in existence.
     */
    function totalSupply(uint256 attrId) external view returns (uint256);

    /**
     * @dev Approve attribute type `attrId` of token `from` to token `to` called by `from` holder.
     *
     * Emits an {AttributeApproval} event.
     */
    function approve(
        uint256 from,
        uint256 to,
        uint256 attrId,
        uint256 amount
    ) external;

    /**
     * @dev Transfers attribute type `attrId` from token type `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     */
    function transfer(
        uint256 from,
        uint256 to,
        uint256 attrId,
        uint256 amount
    ) external;

    /**
     * @dev Transfers attribute type `attrId` from token type `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     */
    function transferFrom(
        uint256 from,
        uint256 to,
        uint256 attrId,
        uint256 amount
    ) external;
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

pragma solidity ^0.8.0;

interface IDaoTreasury {
    /// @dev 铸造Gas事件
    event MintGas(uint256 gasAmount);

    /// @dev 销毁Gas事件
    event BurnGas(uint256 gasAmount);

    /// @dev 出售Gas事件
    event SellGas(uint256 tokenId, uint256 gasAmount);

    /// @dev 购买Gas事件
    event BuyGas(uint256 tokenId, uint256 gasAmount);

    /// @dev 设置最大债务比例
    event SetMaxDebt(uint256 _maxDebt);

    /// @dev 设置Gas积分价格
    event SetGasAttrPrice(uint256 _gasAttrPrice);

    /// @dev 设置Gas税
    event SetGasTax(uint256 _gasTax);

    /// @dev 设置合约持有的NFT tokenId
    event SetHoldNFTId(uint256 _holdNFTId);

    /// @dev 设置DaoVault合约地址
    event SetDaoVault(address _DaoVault);

    /// @dev 设置DaoSponsor合约地址
    event SetDaoSponsor(address _DaoSponsor);

    /// @dev NFT合约地址
    function WEB3DAONFT() external view returns (address);

    /// @dev WETH合约地址
    function WETH() external view returns (address);

    /// @dev DaoVault
    function DaoVault() external view returns (address);

    /// @dev DaoSponsor
    function DaoSponsor() external view returns (address);

    /// @dev NFT合约中Gas attrId
    function GAS_ATTR_ID() external view returns (uint256);

    /// @dev gas属性值和eth兑换比例Gas:ETH 10000:1
    function gasAttrPrice() external view returns (uint256);

    /// @dev 除数
    function max() external view returns (uint256);

    /// @dev 债务数量
    function debt() external view returns (uint256);

    /// @dev 最大债务上限
    function maxDebt() external view returns (uint256);

    /// @dev gas出售税 1%
    function gasTax() external view returns (uint256);

    /// @dev 合约持有的NFT tokenId
    function holdNFTId() external view returns (uint256);

    /**
     * @dev 赞助,锁定期1年
     * @param tokenId 赞助记录到的NFT tokenId
     * @param ethAmount 赞助的weth数量
     */
    function sponsor(uint256 tokenId, uint256 ethAmount) external;

    /**
     * @dev 退出赞助
     * @param tokenId 赞助记录到的NFT tokenId
     * @param sponsorAmount 退出的sponsor值数量
     * @notice 仅限tokenId持有者调用
     */
    function quit(uint256 tokenId, uint256 sponsorAmount) external;

    /**
     * @dev 铸造Gas积分
     * @param gasAmount 铸造的数量
     * @notice 仅限多签合约内部调用
     */
    function mintGas(uint256 gasAmount) external;

    /**
     * @dev 销毁Gas积分
     * @param gasAmount 铸造的数量
     * @notice 仅限多签合约内部调用,仅限当前合约持有的NFT tokenId
     */
    function burnGas(uint256 gasAmount) external;

    /**
     * @dev 出售gas
     * @param tokenId gas记录到的NFT tokenId
     * @param gasAmount 铸造的数量
     * @notice 仅限当前合约持有的NFT tokenId
     */
    function sellGas(uint256 tokenId, uint256 gasAmount) external;

    /**
     * @dev 购买gas
     * @param tokenId gas记录到的NFT tokenId
     * @param ethAmount weth的数量
     */
    function buyGas(uint256 tokenId, uint256 ethAmount) external;

    /**
     * @dev 质押sponsor借出gas
     * @param tokenId 质押sponsor的NFT tokenId
     * @param gasAmount 借出的gas数量
     * @notice 仅限tokenId持有者调用
     */
    function borrowGas(uint256 tokenId, uint256 gasAmount) external;

    /**
     * @dev sponsor归还借出的gas
     * @param tokenId 质押sponsor的NFT tokenId
     * @param gasAmount 归还的gas数量
     * @notice 仅限tokenId持有者调用
     */
    function returnGas(uint256 tokenId, uint256 gasAmount) external;

    /// @dev 设置最大债务比例
    function setMaxDebt(uint256 _maxDebt) external;

    /// @dev 设置Gas积分价格
    function setGasAttrPrice(uint256 _gasAttrPrice) external;

    /// @dev 设置Gas税
    function setGasTax(uint256 _gasTax) external;

    /// @dev 设置合约持有的NFT tokenId
    function setHoldNFTId(uint256 _holdNFTId) external;

    /// @dev 设置DaoVault合约地址
    function setDaoVault(address _DaoVault) external;

    /// @dev 设置DaoSponsor合约地址
    function setDaoSponsor(address _DaoSponsor) external;

    /// @dev 发送NFT
    function transferNFT(
        address token,
        address to,
        uint256 tokenId
    ) external;

    /// @dev 接收NFT
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDaoSponsor {
    /// @dev 锁仓结构体
    struct LockVault {
        uint256 sponsorAmount;
        uint256 stakeAmount;
        uint256 borrowGasAmount;
        uint256 time;
    }

    /// @dev 赞助事件
    event Sponsor(
        uint256 indexed tokenId,
        uint256 ethAmount,
        uint256 sponsorAmount
    );

    /// @dev 退出赞助事件
    event Quit(
        uint256 indexed tokenId,
        uint256 sponsorAmount,
        uint256 quitAmount
    );

    /// @dev 设置DaoVault
    event SetDaoVault(address _DaoVault);

    event SetDaoTreasury(address _DaoTreasury);

    event SetMaxBorrow(uint256 _maxBorrow);

    event BorrowGas(uint256 tokenId, uint256 gasAmount, uint256 stakeAmount);

    event ReturnGas(uint256 tokenId, uint256 gasAmount, uint256 unStakeAmount);

    /// @dev NFT合约地址
    function WEB3DAONFT() external view returns (address);

    /// @dev DaoVault
    function DaoVault() external view returns (address);

    /// @dev DaoTreasury
    function DaoTreasury() external view returns (address);

    /// @dev NFT合约中Sponsor attrId
    function SPONSOR_ATTR_ID() external view returns (uint256);

    /// @dev 最大借款比例
    function maxBorrow() external view returns (uint256);

    /// @dev 除数
    function max() external view returns (uint256);

    /**
     * @dev 返回锁仓数据
     * @param tokenId 指定的tokenId
     * @return LockVault锁仓结构体
     */
    function lockVault(uint256 tokenId)
        external
        view
        returns (LockVault memory);

    /**
     * @dev 赞助,锁定期1年
     * @param tokenId 赞助记录到的NFT tokenId
     * @param ethAmount 赞助的weth数量
     */
    function sponsor(uint256 tokenId, uint256 ethAmount) external;

    /**
     * @dev 退出赞助
     * @param tokenId 赞助记录到的NFT tokenId
     * @param sponsorAmount 退出的sponsor值数量
     * @return quitAmount 退出的ETH数量
     * @notice 仅限tokenId持有者调用
     */
    function quit(uint256 tokenId, uint256 sponsorAmount)
        external
        returns (uint256 quitAmount);

    /**
     * @dev 质押sponsor借出gas
     * @param tokenId 质押sponsor的NFT tokenId
     * @param gasAmount 借出的gas数量
     * @return 是否成功
     * @notice 仅限owner调用
     */
    function borrowGas(uint256 tokenId, uint256 gasAmount)
        external
        returns (bool);

    /**
     * @dev sponsor归还借出的gas
     * @param tokenId 质押sponsor的NFT tokenId
     * @param gasAmount 归还的gas数量
     * @return 是否成功
     * @notice 仅限owner调用
     */
    function returnGas(uint256 tokenId, uint256 gasAmount)
        external
        returns (bool);

    /**
     * @dev 设置DaoVault合约地址
     * @param _DaoVault 新合约地址
     * @notice 仅限owner调用
     */
    function setDaoVault(address _DaoVault) external;

    /**
     * @dev 设置DaoTreasury合约地址
     * @param _DaoTreasury 新合约地址
     * @notice 仅限owner调用
     */
    function setDaoTreasury(address _DaoTreasury) external;

    /**
     * @dev 设置最大借出比例
     * @param _maxBorrow 新比例
     * @notice 仅限owner调用
     */
    function setMaxBorrow(uint256 _maxBorrow) external;
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

// SPDX-License-Identifier: MIT
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