// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./EIP3664/interfaces/IERC3664.sol";
import "./interfaces/IWeb3DAOCN.sol";
import "./interfaces/IDaoVault.sol";
import "./interfaces/IDaoSponsor.sol";
import "./interfaces/IDaoTreasury.sol";
import "./MultiSign.sol";

/**
 * @title [email protected]管理合约
 * @notice 实现功能:
 *         1. 赞助商赞助ETH池,有锁仓时间,退出时根据赞助占比和ETH池体量计算收益
 *         2. 发行Gas积分,按照ETH池子数量在最大债务比例下发行
 *         3. 兑换门票,收到的ETH存入合约
 *         4. 偿还债务,归还eth,同时更新债务数据,如果归还0eth,则只更新债务数据
 *         5. 销毁gas,系统将多余的gas销毁
 *         6. 出售gas,向合约出售gas,换回合约中的eth,同时扣除税务
 *         7. 购买gas,用户使用eth向合约购买gas,合约将持有的gas出售给用户
 *         8. 设置最大债务比例,gas和eth兑换比例,gas税
 */
contract DaoTreasury is MultiSign, IDaoTreasury {
    using Address for address;
    /// @dev NFT合约地址
    address public immutable override WEB3DAONFT;
    /// @dev WETH合约地址
    address public immutable override WETH;
    /// @dev DaoVault
    address public override DaoVault;
    /// @dev DaoSponsor
    address public override DaoSponsor;
    /// @dev NFT合约中Gas attrId
    uint256 public immutable override GAS_ATTR_ID;
    /// @dev gas属性值和eth兑换比例Gas:ETH 10000:1
    uint256 public override gasAttrPrice = 10000;
    /// @dev 除数
    uint256 public constant override max = 10000;
    /// @dev 债务数量
    uint256 public override debt;
    /// @dev 最大债务上限
    uint256 public override maxDebt = 5000;
    /// @dev gas出售税 1%
    uint256 public override gasTax = 100;
    /// @dev 合约持有的NFT tokenId
    uint256 public override holdNFTId;

    /**
     * @dev 构造函数
     * @param _WEB3DAONFT NFT合约地址
     * @param _WETH WETH合约地址
     * @param _DaoVault DaoVault合约地址
     * @param _GAS_ATTR_ID NFT合约中Gas attrId
     */
    constructor(
        address _WEB3DAONFT,
        address _WETH,
        address _DaoVault,
        uint256 _GAS_ATTR_ID
    ) {
        WEB3DAONFT = _WEB3DAONFT;
        WETH = _WETH;
        DaoVault = _DaoVault;
        GAS_ATTR_ID = _GAS_ATTR_ID;
    }

    /// @dev 仅限NFT tokenId持有者
    modifier onlyHolder(uint256 tokenId) {
        require(
            IERC721(WEB3DAONFT).ownerOf(tokenId) == msg.sender,
            "DaoTreasury: caller is not the nft holder"
        );
        _;
    }

    /// @dev See {IDaoTreasury-sponsor}.
    function sponsor(uint256 tokenId, uint256 ethAmount) public override {
        IDaoSponsor(DaoSponsor).sponsor(tokenId, ethAmount);
        // 发送weth到DaoVault
        WETH.functionCall(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                msg.sender,
                DaoVault,
                ethAmount
            )
        );
        IDaoVault(DaoVault).deposit(ethAmount);
    }

    /// @dev See {IDaoTreasury-quit}.
    function quit(uint256 tokenId, uint256 sponsorAmount)
        public
        override
        onlyHolder(tokenId)
    {
        uint256 ethAmount = IDaoSponsor(DaoSponsor).quit(
            tokenId,
            sponsorAmount
        );
        IDaoVault(DaoVault).withdraw(ethAmount, msg.sender);
    }

    /// @dev See {IDaoTreasury-mintGas}.
    function mintGas(uint256 gasAmount) public override {
        // 将gasAmount换算成ethAmount
        uint256 ethAmount = (gasAmount * 1 ether) / gasAttrPrice;
        // 获取DaoVault储备量
        uint256 reserve = IDaoVault(DaoVault).reserve();
        // 确认 (债务+铸造的数量) / 储备量 <= 最大债务比例 / 10000
        require(
            reserve > 0 &&
                (debt * 1 ether + ethAmount) / reserve <=
                (maxDebt * 1 ether) / max,
            "DaoTreasury: debt more than max debt"
        );
        // 债务增加
        debt += ethAmount / 1 ether;
        // 铸造gas
        IWeb3DAOCN(WEB3DAONFT).mint(holdNFTId, GAS_ATTR_ID, gasAmount);
        emit MintGas(gasAmount);
    }

    /// @dev See {IDaoTreasury-burnGas}.
    function burnGas(uint256 gasAmount)
        public
        override
        onlyAddressThis
        onlyHolder(holdNFTId)
    {
        // 债务减少
        debt -= gasAmount / gasAttrPrice;
        // 销毁gas
        IWeb3DAOCN(WEB3DAONFT).burn(holdNFTId, GAS_ATTR_ID, gasAmount);
        emit BurnGas(gasAmount);
    }

    /// @dev See {IDaoTreasury-sellGas}.
    function sellGas(uint256 tokenId, uint256 gasAmount)
        public
        override
        onlyHolder(tokenId)
    {
        // 计算收到的weth数量 = 销毁的gas数量 * (10000 - gas税) / (10000 * 10000)
        uint256 ethAmount = (gasAmount * (max - gasTax)) / (max * gasAttrPrice);
        // 将gas发送到合约持有的NFT
        IERC3664(WEB3DAONFT).transferFrom(
            tokenId,
            holdNFTId,
            GAS_ATTR_ID,
            gasAmount
        );
        // 从DaoVault提取WETH
        IDaoVault(DaoVault).withdraw(ethAmount, msg.sender);
        emit SellGas(tokenId, gasAmount);
    }

    /// @dev See {IDaoTreasury-buyGas}.
    function buyGas(uint256 tokenId, uint256 ethAmount) public override {
        // 发送weth到DaoVault
        WETH.functionCall(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                msg.sender,
                DaoVault,
                ethAmount
            )
        );
        // DaoVault存款
        IDaoVault(DaoVault).deposit(ethAmount);
        // 将gas从合约持有NFT发送到目标NFT
        IERC3664(WEB3DAONFT).transfer(
            holdNFTId,
            tokenId,
            GAS_ATTR_ID,
            ethAmount * gasAttrPrice
        );
        emit BuyGas(tokenId, ethAmount);
    }

    /// @dev See {IDaoTreasury-borrowGas}.
    function borrowGas(uint256 tokenId, uint256 gasAmount)
        public
        override
        onlyHolder(tokenId)
    {
        // 确认sponsor合约质押成功
        require(
            IDaoSponsor(DaoSponsor).borrowGas(tokenId, gasAmount),
            "DaoTreasury: borrowGas error"
        );
        // 从当前合约持有的NFT发送gas
        IERC3664(WEB3DAONFT).transfer(
            holdNFTId,
            tokenId,
            GAS_ATTR_ID,
            gasAmount
        );
    }

    /// @dev See {IDaoTreasury-returnGas}.
    function returnGas(uint256 tokenId, uint256 gasAmount)
        public
        override
        onlyHolder(tokenId)
    {
        // 确认sponsor合约归还成功
        require(
            IDaoSponsor(DaoSponsor).returnGas(tokenId, gasAmount),
            "DaoTreasury: returnGas error"
        );
        // 将gas从tokenId发送到当前合约持有的NFT
        IERC3664(WEB3DAONFT).transferFrom(
            tokenId,
            holdNFTId,
            GAS_ATTR_ID,
            gasAmount
        );
    }

    /// @dev See {IDaoTreasury-setMaxDebt}.
    function setMaxDebt(uint256 _maxDebt) public override onlyAddressThis {
        maxDebt = _maxDebt;
        emit SetMaxDebt(_maxDebt);
    }

    /// @dev See {IDaoTreasury-setGasAttrPrice}.
    function setGasAttrPrice(uint256 _gasAttrPrice)
        public
        override
        onlyAddressThis
    {
        gasAttrPrice = _gasAttrPrice;
        emit SetGasAttrPrice(_gasAttrPrice);
    }

    /// @dev See {IDaoTreasury-setGasTax}.
    function setGasTax(uint256 _gasTax) public override onlyAddressThis {
        gasTax = _gasTax;
        emit SetGasTax(_gasTax);
    }

    /// @dev See {IDaoTreasury-setHoldNFTId}.
    function setHoldNFTId(uint256 _holdNFTId) public override onlyAddressThis {
        holdNFTId = _holdNFTId;
        emit SetHoldNFTId(_holdNFTId);
    }

    /// @dev See {IDaoTreasury-setDaoVault}.
    function setDaoVault(address _DaoVault) public override onlyAddressThis {
        DaoVault = _DaoVault;
        emit SetDaoVault(_DaoVault);
    }

    /// @dev See {IDaoTreasury-setDaoSponsor}.
    function setDaoSponsor(address _DaoSponsor)
        public
        override
        onlyAddressThis
    {
        DaoSponsor = _DaoSponsor;
        emit SetDaoSponsor(_DaoSponsor);
    }

    /// @dev See {IDaoTreasury-transferNFT}.
    function transferNFT(
        address token,
        address to,
        uint256 tokenId
    ) public override onlyAddressThis {
        IERC721(token).transferFrom(address(this), to, tokenId);
    }

    /// @dev See {IDaoTreasury-onERC721Received}.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

/**
 * @title MultiSign
 * @dev Allows multiple parties to agree on transactions before execution.
 * @author colorbay.org
 */
contract MultiSign {
    //委员会的最多人数
    uint256 public MAX_COMMITEE_COUNT = 101;

    //确认事件
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    //撤销确认
    event Revocation(address indexed sender, uint256 indexed transactionId);
    //提交交易
    event Submission(uint256 indexed transactionId);
    //执行交易
    event Execution(uint256 indexed transactionId);
    //执行成功
    event ExecutionSuccess(uint256 indexed transactionId);
    //执行失败
    event ExecutionFailure(uint256 indexed transactionId);
    //添加委员会成员
    event CommiteeAddition(address indexed commitee);
    //移除委员会成员
    event CommiteeRemoval(address indexed commitee);
    //确认数量变更
    event RequirementChange(uint256 required);

    //交易id对交易的映射
    mapping(uint256 => Transaction) public transactions;
    //交易id对应委员会成员对应布尔的映射
    mapping(uint256 => mapping(address => bool)) public confirmations;
    //委员会成员地址对应布尔的映射
    mapping(address => bool) public isCommitee;
    //委员会地址数组
    address[] public commitees;
    //确认数量
    uint256 public required;
    //交易计数
    uint256 public transactionCount;

    //交易构造体
    struct Transaction {
        address destination; //目的地址
        bytes data; //交易数据
        bool executed; //已执行
    }

    modifier onlyAddressThis() {
        require(
            msg.sender == address(this),
            "MultiSign only address(this) can call this"
        );
        _;
    }

    /**
     * @dev 委员会成员不存在.
     */
    modifier commiteeNotExists(address commitee) {
        require(!isCommitee[commitee], "MultiSign commiteeNotExists() Error");
        _;
    }

    /**
     * @dev 委员会成员存在.
     */
    modifier commiteeExists(address commitee) {
        require(isCommitee[commitee], "MultiSign commiteeExists() Error");
        _;
    }

    /**
     * @dev 交易不存在.
     */
    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            "MultiSign transactionExists() Error"
        );
        _;
    }

    /**
     * @dev 已确认.
     */
    modifier confirmed(uint256 transactionId, address commitee) {
        require(
            confirmations[transactionId][commitee],
            "MultiSign confirmed() Error"
        );
        _;
    }

    /**
     * @dev 未确认.
     */
    modifier notConfirmed(uint256 transactionId, address commitee) {
        require(
            !confirmations[transactionId][commitee],
            "MultiSign notConfirmed() Error"
        );
        _;
    }

    /**
     * @dev 未执行.
     */
    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "MultiSign notExecuted() Error"
        );
        _;
    }

    /**
     * @dev 地址非空.
     */
    modifier notNull(address _address) {
        require(_address != address(0), "MultiSign notNull() Error");
        _;
    }

    /**
     * @dev 验证委员会成员数量.
     */
    modifier validRequirement(uint256 commiteeCount, uint256 _required) {
        require(
            commiteeCount > 0 &&
                commiteeCount <= MAX_COMMITEE_COUNT &&
                _required > 0 &&
                _required <= commiteeCount,
            "MultiSign validRequirement() Error"
        );
        _;
    }

    /**
     * @dev 构造函数
     */
    constructor() {
        isCommitee[msg.sender] = true;
        commitees.push(msg.sender);
        required = 1;
    }

    /**
     *
     * @dev 添加委员会成员,
     * @notice 成员不存在,验证成员.onlyAddressThis
     */
    function addCommitee(address commitee)
        public
        commiteeNotExists(commitee)
        notNull(commitee)
        validRequirement(commitees.length + 1, required)
        onlyAddressThis
    {
        isCommitee[commitee] = true;
        commitees.push(commitee);
        emit CommiteeAddition(commitee);
    }

    /**
     *
     * @dev 移除委员会成员
     * @notice 成员存在.onlyAddressThis
     */
    function removeCommitee(address commitee)
        public
        onlyAddressThis
        commiteeExists(commitee)
    {
        isCommitee[commitee] = false;
        for (uint256 i = 0; i < commitees.length - 1; i++) {
            if (commitees[i] == commitee) {
                commitees[i] = commitees[commitees.length - 1];
                break;
            }
        }
        commitees.pop();
        if (required > commitees.length) {
            changeRequirement(commitees.length);
        }
        emit CommiteeRemoval(commitee);
    }

    /**
     *
     * @dev 替换委员会成员
     * @notice 旧成员存在,新成员不存在.onlyAddressThis
     */
    function replaceCommitee(address commitee, address newCommitee)
        public
        onlyAddressThis
        commiteeExists(commitee)
        commiteeNotExists(newCommitee)
    {
        for (uint256 i = 0; i < commitees.length; i++) {
            if (commitees[i] == commitee) {
                commitees[i] = newCommitee;
                break;
            }
        }
        isCommitee[commitee] = false;
        isCommitee[newCommitee] = true;
        emit CommiteeRemoval(commitee);
        emit CommiteeAddition(newCommitee);
    }

    /**
     *
     * @dev 改变确认数量.
     * @param _required 确认数量.
     * @notice 验证确认数量.onlyAddressThis
     */
    function changeRequirement(uint256 _required)
        public
        onlyAddressThis
        validRequirement(commitees.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /**
     *
     * @dev 委员会成员提交并确认交易
     * @param destination 目的地址.
     * @param data 交易数据.
     * @notice 委员会成员存在.
     * @return transactionId 返回交易ID.
     */
    function submitTransaction(address destination, bytes memory data)
        public
        commiteeExists(msg.sender)
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(destination, data);
        confirmTransaction(transactionId);
    }

    /**
     *
     * @dev 委员会成员根据交易id确认交易.
     * @param transactionId 交易ID.
     * @notice 委员会成员存在,交易ID存在,未确认.
     */
    function confirmTransaction(uint256 transactionId)
        public
        commiteeExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**
     *
     * @dev 撤销确认的交易
     * @param transactionId 交易ID.
     * @notice 委员会成员存在,已确认,未执行.
     */
    function revokeConfirmation(uint256 transactionId)
        public
        commiteeExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     *
     * @dev 执行交易.
     * @param transactionId 交易ID.
     * @notice 未执行.
     */
    function executeTransaction(uint256 transactionId)
        internal
        notExecuted(transactionId)
    {
        //如果已确认
        if (isConfirmed(transactionId)) {
            //创建交易构造体
            Transaction storage ta = transactions[transactionId];
            //已执行
            ta.executed = true;
            //发送交易
            (bool status, bytes memory returnedData) = ta.destination.call(
                ta.data
            );

            if (
                status &&
                (returnedData.length == 0 || abi.decode(returnedData, (bool)))
            ) {
                //交易成功
                emit ExecutionSuccess(transactionId);
            } else {
                //交易失败
                emit ExecutionFailure(transactionId);
                //交易失败
                ta.executed = false;
            }
        }
    }

    /**
     *
     * @dev 返回确认状态
     * @param transactionId 交易ID.
     * @return ret 确认状态.
     */
    function isConfirmed(uint256 transactionId) public view returns (bool ret) {
        uint256 count = 0;
        for (uint256 i = 0; i < commitees.length; i++) {
            //如果确认映射中交易id对应委员会成员为true
            if (confirmations[transactionId][commitees[i]]) {
                count++;
            }
            if (count >= required) {
                ret = true;
            }
        }
    }

    /**
     *
     * @dev 添加交易到交易映射,如果交易不存在.
     * @param destination 目的地址.
     * @param data 交易数据.
     * @notice 目的地址非空.
     * @return transactionId 交易ID.
     */
    function addTransaction(address destination, bytes memory data)
        internal
        notNull(destination)
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            data: data,
            executed: false
        });
        transactionCount++;
        emit Submission(transactionId);
    }

    /**
     *
     * @dev 返回指定交易id的确认数量.
     * @param transactionId 交易ID.
     * @return count 确认数量.
     */
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < commitees.length; i++) {
            if (confirmations[transactionId][commitees[i]]) {
                count++;
            }
        }
    }

    /**
     *
     * @dev 返回委员会成员数组.
     * @return 委员会成员地址数组
     */
    function getCommitees() public view returns (address[] memory) {
        return commitees;
    }

    /**
     *
     * @dev 返回指定交易ID中确认的委员会成员数组
     * @param transactionId 交易ID.
     * @return _confirmations 委员会成员地址数组
     */
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](commitees.length);
        uint256 count = 0;
        for (uint256 i = 0; i < commitees.length; i++) {
            if (confirmations[transactionId][commitees[i]]) {
                confirmationsTemp[count] = commitees[i];
                count++;
            }
        }
        _confirmations = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
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