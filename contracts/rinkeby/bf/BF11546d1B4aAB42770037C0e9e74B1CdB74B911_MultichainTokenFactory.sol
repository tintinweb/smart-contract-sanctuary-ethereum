// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "../token/IBonfireTokenTracker.sol";
import "../token/IMultichainTokenFactory.sol";
import "../token/MultichainToken.sol";

/*
 * The main purpose of the MultichainTokenFactory is to allow MultichainTokens
 * that have the exact same address on different blockchains in a more
 * automated way such that BonfireTokenWrapper can trust the outcome. There can
 * only be one Token, but it acts differently on source or other chains.
 */

contract MultichainTokenFactory is IMultichainTokenFactory {
    address public constant wrapper =
        address(0xBFbb27219f18d7463dD91BB4721D445244F5d22D);
    address public constant tracker =
        address(0xBFac04803249F4C14f5d96427DA22a814063A5E1);

    error SupplyMismatch(uint256 actual, uint256 claimed);

    function salt(address creator, uint256 pepper)
        public
        pure
        returns (bytes32)
    {
        return (keccak256(abi.encodePacked(creator, pepper)));
    }

    function multichainTokenAddress(
        address creator,
        address sourceToken,
        uint256 sourceTotalSupply,
        uint256 chainid,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals,
        uint256 pepper
    ) external view override returns (address multichainToken) {
        bytes memory bytecode = MultichainTokenFactory(this).getBytecode(
            sourceToken,
            sourceTotalSupply,
            chainid,
            name,
            symbol,
            totalSupply,
            decimals
        );
        multichainToken = _multichainTokenAddress(
            bytecode,
            salt(creator, pepper)
        );
    }

    function _multichainTokenAddress(bytes memory creationCode, bytes32 _salt)
        internal
        view
        returns (address multichainToken)
    {
        multichainToken = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            _salt,
                            keccak256(creationCode)
                        )
                    )
                )
            )
        );
    }

    function getMultichainToken(
        address creator,
        address sourceToken,
        uint256 sourceTotalSupply,
        uint256 chainid,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals,
        uint256 pepper
    ) external override returns (address multichainToken) {
        bytes memory bytecode = MultichainTokenFactory(this).getBytecode(
            sourceToken,
            sourceTotalSupply,
            chainid,
            name,
            symbol,
            totalSupply,
            decimals
        );
        bytes32 _salt = salt(creator, pepper);
        multichainToken = _multichainTokenAddress(bytecode, _salt);
        uint32 size;
        assembly {
            size := extcodesize(multichainToken)
        }
        if (size == 0) {
            if (chainid == block.chainid) {
                if (sourceTotalSupply != IERC20(sourceToken).totalSupply()) {
                    revert SupplyMismatch(
                        sourceTotalSupply,
                        IERC20(sourceToken).totalSupply()
                    ); //bad sourceTotalSupply
                }
            }
            _createMultichainToken(bytecode, _salt);
            IBonfireTokenTracker(tracker).registerToken(multichainToken);
            IBonfireTokenWrapper(wrapper).addMultichainToken(multichainToken);
            emit TokenCreation(creator, sourceToken, chainid, multichainToken);
        }
    }

    function getBytecode(
        address sourceToken,
        uint256 sourceTotalSupply,
        uint256 chainid,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals
    ) external pure returns (bytes memory bytecode) {
        bytecode = type(MultichainToken).creationCode;
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode(
                sourceToken,
                sourceTotalSupply,
                chainid,
                name,
                symbol,
                totalSupply,
                decimals
            )
        );
    }

    function _createMultichainToken(bytes memory bytecode, bytes32 _salt)
        internal
    {
        address multichainToken;
        assembly {
            multichainToken := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                _salt
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IBonfireTokenTracker {
    function getObserver(address token) external view returns (address o);

    function getTotalTaxP(address token) external view returns (uint256 p);

    function getReflectionTaxP(address token) external view returns (uint256 p);

    function getTaxQ(address token) external view returns (uint256 q);

    function reflectingSupply(address token, uint256 transferAmount)
        external
        view
        returns (uint256 amount);

    function includedSupply(address token)
        external
        view
        returns (uint256 amount);

    function excludedSupply(address token)
        external
        view
        returns (uint256 amount);

    function storeTokenReference(address token, uint256 chainid) external;

    function tokenid(address token, uint256 chainid)
        external
        pure
        returns (uint256);

    function getURI(uint256 _tokenid) external view returns (string memory);

    function getProperties(address token)
        external
        view
        returns (string memory properties);

    function registerToken(address proxy) external;

    function registeredTokens(uint256 index)
        external
        view
        returns (uint256 tokenid);

    function registeredProxyTokens(uint256 sourceTokenid, uint256 index)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IMultichainTokenFactory {
    event TokenCreation(
        address creator,
        address sourceToken,
        uint256 chainId,
        address targetToken
    );

    function multichainTokenAddress(
        address creator,
        address sourceToken,
        uint256 sourceTotalSupply,
        uint256 chainId,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals,
        uint256 pepper
    ) external view returns (address multichainToken);

    function getMultichainToken(
        address creator,
        address sourceToken,
        uint256 sourceTotalSupply,
        uint256 chainId,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals,
        uint256 pepper
    ) external returns (address multichainToken);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../token/IBonfireTokenWrapper.sol";
import "../token/IMultichainToken.sol";

contract MultichainToken is IERC20Metadata, ERC1155Holder, IMultichainToken {
    using Address for address;

    address public constant wrapper =
        address(0xBFbb27219f18d7463dD91BB4721D445244F5d22D);
    uint256 private constant MAX_INT = 2**256 - 1;

    address public override sourceToken;
    uint256 public chainid;
    string public override name;
    string public override symbol;
    uint256 public override totalSupply;
    uint8 public override decimals;
    uint256 public multiplier;

    mapping(address => uint256) public shares;
    mapping(address => mapping(address => uint256)) public override allowance;

    error BadUse(uint256 location);
    error AddressMismatch(address a, address b);
    error BadValues(uint256 location, uint256 v1, uint256 v2);

    modifier wrapperOnly() {
        if (msg.sender != wrapper) {
            revert AddressMismatch(msg.sender, wrapper); //wrapper exclusive transaction
        }
        _;
    }

    constructor(
        address _sourceToken,
        uint256 _sourceTotalSupply,
        uint256 _chainid,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals
    ) {
        if (_totalSupply == 0) {
            revert BadUse(0); //invalid totalSupply
        }
        sourceToken = _sourceToken;
        chainid = _chainid;
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
        uint256 MAX_SHARES = (MAX_INT - (MAX_INT % _sourceTotalSupply));
        if (MAX_SHARES < _sourceTotalSupply * 100) {
            revert BadValues(0, MAX_SHARES, _sourceTotalSupply * 100);
        }
        if (MAX_SHARES < _totalSupply * 100) {
            revert BadValues(1, MAX_SHARES, _totalSupply * 100);
        }
        multiplier = MAX_SHARES / _totalSupply;
    }

    function mint(address to, uint256 _token) external override {
        uint256 _shares = tokenToShares(_token);
        shares[to] += _shares;
        IBonfireTokenWrapper(wrapper).reportMint(msg.sender, _shares);
        emit Transfer(address(0), to, sharesToToken(_shares));
    }

    function mintShares(address to, uint256 _shares)
        external
        virtual
        override
        wrapperOnly
    {
        shares[to] += _shares;
        emit Transfer(address(0), to, sharesToToken(_shares));
    }

    /**
     * In contrast to regular burn functions, this one is reversible by design.
     * The BonfireTokenWrapper contract increases the bridgeAllowance for the
     * sender of this call, effectively locking the corresponding shares.
     * Unless the BonfireTokenWrapper authority adjusts this very
     * bridgeAllowance, msg.sender can at a later point in time thus call the
     * mint function with the same parameters to unlock the Tokens.
     */
    function burn(address from, uint256 _token) external override {
        uint256 _shares = tokenToShares(_token);
        if (shares[from] < _shares) {
            revert BadValues(3, shares[from], _shares); //insufficient balance
        }
        unchecked {
            shares[from] -= _shares;
        }
        IBonfireTokenWrapper(wrapper).reportBurn(msg.sender, _shares);
        emit Transfer(from, address(0), sharesToToken(_shares));
    }

    function burnShares(
        address from,
        uint256 _shares,
        address burner
    ) external virtual override wrapperOnly {
        uint256 tokens = sharesToToken(_shares);
        if (burner != from) {
            if (allowance[from][burner] < tokens) {
                revert BadValues(4, allowance[from][burner], tokens); //allowance
            }
            unchecked {
                allowance[from][burner] -= tokens;
            }
        }
        if (shares[from] < _shares) {
            revert BadValues(5, shares[from], _shares); //insufficient balance
        }
        unchecked {
            shares[from] -= _shares;
        }
        emit Transfer(from, address(0), tokens);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IBonfireProxyToken).interfaceId ||
            interfaceId == type(IMultichainToken).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function circulatingSupply() public view override returns (uint256) {
        return
            sharesToToken(
                IBonfireTokenWrapper(wrapper).sharesBalanceOf(
                    IBonfireTokenWrapper(wrapper).tokenid(sourceToken, chainid),
                    address(this)
                )
            );
    }

    function balanceOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return sharesToToken(shares[account]);
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, to, tokenToShares(amount));
    }

    function transferShares(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 _shares
    ) internal virtual returns (bool) {
        if (to == address(0)) {
            revert BadUse(1); //no transfer to zero address allowed
        }
        if (shares[from] < _shares) {
            revert BadValues(6, shares[from], _shares); //transfer amount exceeds balance
        }
        unchecked {
            shares[from] -= _shares;
        }
        shares[to] += _shares;
        emit Transfer(from, to, sharesToToken(_shares));
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        return transferSharesFrom(from, to, tokenToShares(amount));
    }

    function transferSharesFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 tokenAmount = sharesToToken(amount);
        if (allowance[from][msg.sender] < tokenAmount) {
            revert BadValues(7, allowance[from][msg.sender], tokenAmount); //transfer amount exceeds allowance
        }
        unchecked {
            allowance[from][msg.sender] -= tokenAmount;
        }
        return _transfer(from, to, amount);
    }

    function tokenToShares(uint256 amount)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return amount * multiplier;
    }

    function sharesToToken(uint256 amount)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return amount / multiplier;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBonfireTokenWrapper is IERC1155 {
    event SecureBridgeUpdate(address bridge, bool enabled);
    event BridgeUpdate(
        address bridge,
        address proxyToken,
        address sourceToken,
        uint256 sourceChain,
        uint256 allowanceShares
    );
    event FactoryUpdate(address factory, bool enabled);
    event MultichainTokenUpdate(address token, bool enabled);

    function factory(address account) external view returns (bool approved);

    function multichainToken(address account)
        external
        view
        returns (bool verified);

    function tokenid(address token, uint256 chain)
        external
        pure
        returns (uint256);

    function addMultichainToken(address target) external;

    function reportMint(address bridge, uint256 shares) external;

    function reportBurn(address bridge, uint256 shares) external;

    function tokenBalanceOf(address sourceToken, address account)
        external
        view
        returns (uint256 tokenAmount);

    function sharesBalanceOf(uint256 sourceTokenId, address account)
        external
        view
        returns (uint256 sharesAmount);

    function lockedTokenTotal(address sourceToken)
        external
        view
        returns (uint256);

    function tokenToShares(address sourceToken, uint256 tokenAmount)
        external
        view
        returns (uint256 sharesAmount);

    function sharesToToken(address sourceToken, uint256 sharesAmount)
        external
        view
        returns (uint256 tokenAmount);

    function moveShares(
        address oldProxy,
        address newProxy,
        uint256 sharesAmountIn,
        address from,
        address to
    ) external returns (uint256 tokenAmountOut, uint256 sharesAmountOut);

    function depositToken(
        address proxyToken,
        address to,
        uint256 amount
    ) external returns (uint256 tokenAmount, uint256 sharesAmount);

    function announceDeposit(address sourceToken) external;

    function executeDeposit(address proxyToken, address to)
        external
        returns (uint256 tokenAmount, uint256 sharesAmount);

    function currentDeposit() external view returns (address sourceToken);

    function withdrawShares(
        address proxyToken,
        address to,
        uint256 amount
    ) external returns (uint256 tokenAmount, uint256 sharesAmount);

    function withdrawSharesFrom(
        address proxyToken,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 tokenAmount, uint256 sharesAmount);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "../token/IBonfireProxyToken.sol";

interface IMultichainToken is IBonfireProxyToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../token/IBonfireTokenWrapper.sol";

interface IBonfireProxyToken is IERC20, IERC1155Receiver {
    function sourceToken() external view returns (address);

    function chainid() external view returns (uint256);

    function wrapper() external view returns (address);

    function circulatingSupply() external view returns (uint256);

    function transferShares(address to, uint256 amount) external returns (bool);

    function transferSharesFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mintShares(address to, uint256 shares) external;

    function burnShares(
        address from,
        uint256 shares,
        address burner
    ) external;

    function tokenToShares(uint256 amount) external view returns (uint256);

    function sharesToToken(uint256 amount) external view returns (uint256);
}