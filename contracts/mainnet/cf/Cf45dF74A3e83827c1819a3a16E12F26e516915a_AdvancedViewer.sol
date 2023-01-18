// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IDaoViewer.sol";
import "../interfaces/IDao.sol";

contract AdvancedViewer {
    using Address for address;

    address private immutable factory;
    IDaoViewer private immutable daoViewer;

    constructor(address _factory, address _daoViewer) {
        factory = _factory;
        daoViewer = IDaoViewer(_daoViewer);
    }

    function userDaos(
        uint256 start,
        uint256 end,
        address user
    ) external view returns (address[] memory) {
        address _factory = factory;

        address[] memory _userDaos = new address[](30);

        uint256 j = 0;

        for (uint256 i = start; i < end; i++) {
            address daoAddress = abi.decode(
                _factory.functionStaticCall(
                    abi.encodeWithSelector(hex"b2dabed4", i)
                ),
                (address)
            );

            if (IERC20(daoAddress).balanceOf(user) > 0) {
                _userDaos[j] = daoAddress;
                j++;
            }
        }

        return _userDaos;
    }

    function getDaos(uint256 start, uint256 end)
        external
        view
        returns (address[] memory)
    {
        address _factory = factory;

        address[] memory _daos = new address[](end - start);

        for (uint256 i = start; i < end; i++) {
            address daoAddress = abi.decode(
                _factory.functionStaticCall(
                    abi.encodeWithSelector(hex"b2dabed4", i)
                ),
                (address)
            );

            _daos[i - start] = daoAddress;
        }

        return _daos;
    }

    function getDaosInfo(address[] memory daoAddresses)
        external
        view
        returns (DaoInfo[] memory)
    {
        DaoInfo[] memory daosInfo = new DaoInfo[](daoAddresses.length);

        for (uint256 i = 0; i < daoAddresses.length; i++) {
            daosInfo[i] = daoViewer.getDao(daoAddresses[i]);
        }

        return daosInfo;
    }

    function getDaosExecutedVoting(address[] memory daoAddresses)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory daosExecutedVoting = new uint256[](
            daoAddresses.length
        );

        for (uint256 i = 0; i < daoAddresses.length; i++) {
            daosExecutedVoting[i] = (IDao(daoAddresses[i]).getExecutedVoting())
                .length;
        }

        return daosExecutedVoting;
    }

    function read(address[] calldata targets, bytes[] calldata data)
        external
        view
        returns (bytes[] memory results)
    {
        results = new bytes[](targets.length);

        for (uint256 i = 0; i < targets.length; i++) {
            results[i] = targets[i].functionStaticCall(data[i]);
        }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/IShop.sol";

struct DaoInfo {
    address dao;
    string daoName;
    string daoSymbol;
    address lp;
    string lpName;
    string lpSymbol;
}

struct DaoConfiguration {
    bool gtMintable;
    bool gtBurnable;
    address lpAddress;
    bool lpMintable;
    bool lpBurnable;
    bool lpMintableStatusFrozen;
    bool lpBurnableStatusFrozen;
    uint256 permittedLength;
    uint256 adaptersLength;
    uint256 monthlyCost;
    uint256 numberOfPrivateOffers;
}

interface IDaoViewer {
    function getDao(address _dao) external view returns (DaoInfo memory);

    function getDaos(address _factory) external view returns (DaoInfo[] memory);

    function userDaos(address _user, address _factory)
        external
        view
        returns (DaoInfo[] memory);

    function getShare(address _dao, address[] memory _users)
        external
        view
        returns (
            uint256 share,
            uint256 totalSupply,
            uint8 quorum
        );

    function getShares(address _dao, address[][] memory _users)
        external
        view
        returns (
            uint256[] memory shares,
            uint256 totalSupply,
            uint8 quorum
        );

    function balances(address[] memory users, address[] memory tokens)
        external
        view
        returns (uint256[] memory);

    function getHashStatuses(address _dao, bytes32[] memory _txHashes)
        external
        view
        returns (bool[] memory);

    function getDaoConfiguration(address _factory, address _dao)
        external
        view
        returns (DaoConfiguration memory);

    function getInvestInfo(address _factory)
        external
        view
        returns (
            DaoInfo[] memory,
            IShop.PublicOffer[] memory,
            string[] memory,
            uint8[] memory,
            uint256[] memory
        );

    function getPrivateOffersInfo(address _factory)
        external
        view
        returns (
            DaoInfo[] memory,
            uint256[] memory,
            IShop.PrivateOffer[] memory,
            string[] memory,
            uint8[] memory
        );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IDao {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function lp() external view returns (address);

    function burnLp(
        address _recipient,
        uint256 _share,
        address[] memory _tokens,
        address[] memory _adapters,
        address[] memory _pools
    ) external returns (bool);

    function setLp(address _lp) external returns (bool);

    function quorum() external view returns (uint8);

    function executedTx(bytes32 _txHash) external view returns (bool);

    function mintable() external view returns (bool);

    function burnable() external view returns (bool);

    function numberOfPermitted() external view returns (uint256);

    function numberOfAdapters() external view returns (uint256);

    function executePermitted(
        address _target,
        bytes calldata _data,
        uint256 _value
    ) external returns (bool);

    struct ExecutedVoting {
        address target;
        bytes data;
        uint256 value;
        uint256 nonce;
        uint256 timestamp;
        uint256 executionTimestamp;
        bytes32 txHash;
        bytes[] sigs;
    }

    function getExecutedVoting()
        external
        view
        returns (ExecutedVoting[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IShop {
    struct PublicOffer {
        bool isActive;
        address currency;
        uint256 rate;
    }

    function publicOffers(address _dao)
        external
        view
        returns (PublicOffer memory);

    struct PrivateOffer {
        bool isActive;
        address recipient;
        address currency;
        uint256 currencyAmount;
        uint256 lpAmount;
    }

    function privateOffers(address _dao, uint256 _index)
        external
        view
        returns (PrivateOffer memory);

    function numberOfPrivateOffers(address _dao)
        external
        view
        returns (uint256);

    function buyPrivateOffer(address _dao, uint256 _id) external returns (bool);
}