// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../token/IBonfireTokenTracker.sol";
import "../token/IBonfireProxyToken.sol";
import "../utils/BonfireTokenHelper.sol";

struct TokenStats {
    address observer;
    uint32 totalTaxP;
    uint32 reflectionTaxP;
    uint32 taxQ;
    address[] excluded;
}

struct Untaxing {
    uint256 lastBlock;
    address[] unaffected;
}

struct TokenReference {
    address token;
    uint256 chain;
}

contract BonfireTokenTracker is IBonfireTokenTracker {
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(address => TokenStats) public stats;
    mapping(address => Untaxing) public untaxing;

    mapping(uint256 => address[]) public override registeredProxyTokens;
    uint256[] public override registeredTokens;
    mapping(uint256 => bytes1) public registry;
    mapping(address => address[]) public burners;

    mapping(uint256 => TokenReference) tokenReference;

    event TokenRegistered(
        address sourceToken,
        uint256 chainid,
        address proxyToken
    );

    function registerToken(address proxy) external virtual override {
        require(
            registry[tokenid(proxy, block.chainid)] & 0x02 == 0x00,
            "BonfireTokenWrapper: proxy already registered"
        );
        address sourceToken = IBonfireProxyToken(proxy).sourceToken();
        uint256 chainid = IBonfireProxyToken(proxy).chainid();
        uint256 sourceid = tokenid(sourceToken, chainid);
        uint256 proxyid = tokenid(proxy, block.chainid);
        if (registry[sourceid] & 0x01 == 0x00) {
            registeredTokens.push(sourceid);
            registry[sourceid] |= 0x01;
            storeTokenReference(sourceToken, chainid);
        }
        registry[proxyid] |= 0x02;
        registeredProxyTokens[sourceid].push(proxy);
        emit TokenRegistered(sourceToken, chainid, proxy);
    }

    function storeTokenReference(address token, uint256 chain) public override {
        tokenReference[tokenid(token, chain)] = TokenReference(token, chain);
    }

    function tokenid(address token, uint256 chainid)
        public
        pure
        override
        returns (uint256 _tokenid)
    {
        _tokenid = uint256(keccak256(abi.encodePacked(token, chainid)));
    }

    function getURI(uint256 _tokenid)
        external
        view
        override
        returns (string memory metadata)
    {
        address token = tokenReference[_tokenid].token;
        uint256 chain = tokenReference[_tokenid].chain;
        if (chain == block.chainid) {
            metadata = _nativeTokenURI(token, chain, _tokenid);
        } else if (chain > 0) {
            metadata = _foreignTokenURI(token, chain, _tokenid);
        } else {
            metadata = string(
                abi.encodePacked(
                    '{"tokenid": "',
                    Strings.toString(_tokenid),
                    '"}'
                )
            );
        }
    }

    function _corepack(
        address token,
        uint256 chainid,
        uint256 _tokenid
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"address": "',
                    this.checksumEncode(
                        bytes(Strings.toHexString(uint160(token), 20))
                    ),
                    '", "chainid": "',
                    Strings.toString(chainid),
                    '", "tokenid": "',
                    Strings.toString(_tokenid),
                    '"'
                )
            );
    }

    function _foreignTokenURI(
        address _token,
        uint256 chainid,
        uint256 _tokenid
    ) internal view returns (string memory text) {
        text = string(
            abi.encodePacked("{", _corepack(_token, chainid, _tokenid), "}")
        );
    }

    function _nativeTokenURI(
        address token,
        uint256 chainid,
        uint256 _tokenid
    ) internal view returns (string memory metadata) {
        string memory name = IERC20Metadata(token).name();
        string memory properties = this.getProperties(token);
        metadata = string(
            abi.encodePacked(
                '{"name": "',
                name,
                '", ',
                _corepack(token, chainid, _tokenid)
            )
        );
        string memory reg = (registry[_tokenid] == 0x03)
            ? "source+proxy"
            : (registry[_tokenid] == 0x02)
            ? "proxy"
            : (registry[_tokenid] == 0x01)
            ? "source"
            : "none";
        metadata = string(
            abi.encodePacked(metadata, ', "registered": "', reg, '"')
        );
        metadata = string(
            abi.encodePacked(metadata, ', "properties": ', properties, "}")
        );
    }

    function _isBurner(address wallet) public pure returns (bool) {
        return (uint160(wallet) <= uint160(0xffffffff));
    }

    function addBurnerWallet(address token, address burner) external {
        require(
            _isBurner(burner),
            "BonfireTokenTracker: Likely not a burner wallet"
        );
        require(
            IERC20(token).balanceOf(burner) > 0,
            "BonfireTokenTracker: Burner wallet empty"
        );
        for (uint256 i = 0; i < burners[token].length; i++) {
            require(
                burners[token][i] != burner,
                "BonfireTokenTracker: Burner already registered"
            );
        }
        burners[token].push(burner);
    }

    function getBurnAmount(address token) public view returns (uint256 amount) {
        for (uint256 i = 0; i < burners[token].length; i++) {
            amount += IERC20(token).balanceOf(burners[token][i]);
        }
    }

    function untaxToken(address token, uint256 amount) external {
        /*
         * The intention of this function is to allow decentralized removal of tax information.
         * To do so we require 10 independent accounts to show that they don't pay any taxes
         * anymore with 1200 blocks in between each demonstration.
         */
        require(
            untaxing[token].lastBlock + 1200 < block.number,
            "BonfireTokenTracker: untaxing transactions require 1200 blocks in between"
        );
        for (uint256 i = 0; i < untaxing[token].unaffected.length; i++) {
            require(
                untaxing[token].unaffected[i] != msg.sender,
                "BonfireTokenTracker: wallet already shown to be unaffected"
            );
        }
        for (uint256 i = 0; i < stats[token].excluded.length; i++) {
            require(
                stats[token].excluded[i] != msg.sender,
                "BonfireTokenTracker: excluded address might be exempt from tax"
            );
        }
        uint256 beforeS = IERC20(token).balanceOf(msg.sender);
        require(
            (beforeS * stats[token].totalTaxP) / stats[token].taxQ > 0,
            "BonfireTokenTracker: transfer amount too low"
        );
        IERC20(token).safeTransferFrom(msg.sender, msg.sender, amount);
        if (IERC20(token).balanceOf(msg.sender) != beforeS) {
            delete untaxing[token].unaffected;
        } else {
            untaxing[token].unaffected.push(msg.sender);
            untaxing[token].lastBlock = block.number;
        }
        if (untaxing[token].unaffected.length > 9) {
            delete untaxing[token];
            stats[token].taxQ = 1;
            stats[token].totalTaxP = 0;
            stats[token].reflectionTaxP = 0;
        }
    }

    function markWallets(
        address token,
        address observer,
        address[] calldata wallets,
        uint256 amount
    ) external {
        uint256[] memory before = new uint256[](wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            require(
                wallets[i] != msg.sender && wallets[i] != observer,
                "BonfireTokenTracker: bad marking"
            );
            before[i] = IERC20(token).balanceOf(wallets[i]);
        }
        require(
            msg.sender != observer,
            "BonfireTokenTracker: sender can not observe reflection"
        );
        uint256 B = IERC20(token).balanceOf(observer);
        IERC20(token).safeTransferFrom(msg.sender, msg.sender, amount);
        uint256 A = IERC20(token).balanceOf(observer);
        require(A > B, "BonfireTokenTracker: no reflection observed");
        for (uint256 i = 0; i < wallets.length; i++) {
            if (IERC20(token).balanceOf(wallets[i]) > before[i]) {
                //should not be excluded
                for (uint256 j = 0; j < stats[token].excluded.length; j++) {
                    if (stats[token].excluded[j] == wallets[i]) {
                        stats[token].excluded[j] = stats[token].excluded[
                            stats[token].excluded.length - 1
                        ];
                        stats[token].excluded.pop();
                    }
                }
            } else {
                if ((before[i] * A) / B > before[i]) {
                    //should definitely be excluded
                    //optimistically pushing
                    stats[token].excluded.push(wallets[i]);
                    if (stats[token].excluded.length > 1) {
                        for (
                            uint256 j = 0;
                            j < stats[token].excluded.length - 1;
                            j++
                        ) {
                            if (stats[token].excluded[j] == wallets[i]) {
                                //check returns that wallet was already excluded, we need to pop it
                                stats[token].excluded.pop();
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    function updateTokenStats(
        address token,
        address observer,
        uint256 amount,
        uint256 reflectionTaxP,
        uint256 totalTaxP,
        uint256 taxQ
    ) external {
        require(
            observer != address(0) &&
                observer != msg.sender &&
                !observer.isContract() &&
                _isBurner(observer),
            "BonfireTokenTracker: observer should be an indifferent burn wallet"
        );
        for (uint256 i = 0; i < stats[token].excluded.length; i++) {
            require(
                observer != stats[token].excluded[i],
                "BonfireTokenTracker: observer can not be excluded"
            );
            require(
                msg.sender != stats[token].excluded[i],
                "BonfireTokenTracker: sender can not be excluded"
            );
        }
        //before
        require(
            taxQ > reflectionTaxP + totalTaxP && totalTaxP >= reflectionTaxP,
            "BonfireTokenTracker: impossible tax parameters"
        );
        stats[token].reflectionTaxP = uint32(reflectionTaxP);
        stats[token].totalTaxP = uint32(totalTaxP);
        stats[token].taxQ = uint32(taxQ);
        uint256[] memory b = new uint256[](3); //balances
        b[0] = IERC20(token).balanceOf(observer);
        b[1] = IERC20(token).balanceOf(msg.sender);
        b[2] = stats[token].observer != address(0) &&
            stats[token].observer != observer
            ? IERC20(token).balanceOf(stats[token].observer)
            : uint256(0);
        uint256[] memory x = new uint256[](3); //expectations
        uint256 supply = _reflectingSupply(
            includedSupply(token),
            reflectionTaxP,
            taxQ,
            amount
        );
        x[0] = b[0] + ((((amount * reflectionTaxP) / taxQ) * b[0]) / supply);
        x[1] = b[1] - ((amount * totalTaxP) / taxQ);
        x[1] = x[1] + ((((amount * reflectionTaxP) / taxQ) * x[1]) / supply);
        x[2] = b[2] > 0
            ? b[2] + ((((amount * reflectionTaxP) / taxQ) * b[2]) / supply)
            : uint256(0);
        //transfer
        IERC20(token).safeTransferFrom(msg.sender, msg.sender, amount);
        //after
        b[0] = IERC20(token).balanceOf(observer);
        b[1] = IERC20(token).balanceOf(msg.sender);
        b[2] = b[2] > 0
            ? IERC20(token).balanceOf(stats[token].observer)
            : uint256(0);
        require(
            _isClose(b[0], x[0], 10) && _isClose(b[1], x[1], 10),
            "BonfireTokenTracker: expectations not met"
        );
        if (b[0] > b[2] || !_isClose(b[2], x[2], 10)) {
            stats[token].observer = observer;
        }
    }

    function _isClose(
        uint256 v1,
        uint256 v2,
        uint256 maxdiff
    ) internal pure returns (bool) {
        uint256 diff = v1 > v2 ? v1 - v2 : v2 - v1;
        return (diff <= maxdiff);
    }

    function getObserver(address token)
        external
        view
        virtual
        override
        returns (address o)
    {
        o = stats[token].observer;
    }

    function getTotalTaxP(address token)
        public
        view
        virtual
        override
        returns (uint256 p)
    {
        p = uint256(stats[token].totalTaxP);
    }

    function getReflectionTaxP(address token)
        public
        view
        virtual
        override
        returns (uint256 p)
    {
        p = uint256(stats[token].reflectionTaxP);
    }

    function getTaxQ(address token)
        public
        view
        virtual
        override
        returns (uint256 q)
    {
        q = stats[token].taxQ > 0 ? uint256(stats[token].taxQ) : uint256(1);
    }

    function _reflectingSupply(
        uint256 _includedSupply,
        uint256 reflectionP,
        uint256 reflectionQ,
        uint256 transferAmount
    ) internal pure returns (uint256 amount) {
        amount = (_includedSupply -
            ((transferAmount * reflectionP) / reflectionQ));
    }

    function reflectingSupply(address token, uint256 transferAmount)
        external
        view
        virtual
        override
        returns (uint256 amount)
    {
        amount = _reflectingSupply(
            includedSupply(token),
            getReflectionTaxP(token),
            getTaxQ(token),
            transferAmount
        );
    }

    function includedSupply(address token)
        public
        view
        virtual
        override
        returns (uint256 amount)
    {
        amount =
            BonfireTokenHelper.circulatingSupply(token) -
            excludedSupply(token);
    }

    function excludedSupply(address token)
        public
        view
        virtual
        override
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < stats[token].excluded.length; i++) {
            amount += IERC20(token).balanceOf(stats[token].excluded[i]);
        }
    }

    uint8 constant intm = uint8(bytes1("7"));
    uint8 constant inta = uint8(bytes1("a"));
    uint8 constant intf = uint8(bytes1("f"));
    uint8 constant diffAa = uint8(bytes1("a")) - uint8(bytes1("A"));

    function checksumEncode(bytes calldata input)
        external
        pure
        returns (string memory output)
    {
        bytes memory bStr = input;
        bytes memory hashedAddress = bytes(
            Strings.toHexString(uint256(keccak256(input[2:])), 32)
        );
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= inta) && (uint8(bStr[i]) <= intf)) {
                if (uint8(hashedAddress[i]) > intm) {
                    bStr[i] = bytes1(uint8(bStr[i]) - diffAa);
                }
            }
        }
        return string(abi.encodePacked(bStr));
    }

    function getProperties(address _token)
        external
        view
        virtual
        override
        returns (string memory properties)
    {
        IERC20Metadata token = IERC20Metadata(_token);
        properties = string(
            abi.encodePacked(
                '{"address": "',
                this.checksumEncode(
                    bytes(Strings.toHexString(uint160(_token), 20))
                ),
                '"'
            )
        );
        try token.name() returns (string memory text) {
            properties = string(
                abi.encodePacked(properties, ', "name": "', text, '"')
            );
        } catch (bytes memory) {}
        try token.symbol() returns (string memory text) {
            properties = string(
                abi.encodePacked(properties, ', "symbol": "', text, '"')
            );
        } catch (bytes memory) {}
        try token.decimals() returns (uint8 amount) {
            properties = string(
                abi.encodePacked(
                    properties,
                    ', "decimals": "',
                    Strings.toString(amount),
                    '"'
                )
            );
        } catch (bytes memory) {}
        try token.totalSupply() returns (uint256 amount) {
            uint256 circulating = BonfireTokenHelper.circulatingSupply(_token);
            if (circulating != amount) {
                properties = string(
                    abi.encodePacked(
                        properties,
                        ', "circulatingSupply": "',
                        Strings.toString(circulating),
                        '"'
                    )
                );
            }
            properties = string(
                abi.encodePacked(
                    properties,
                    ', "totalSupply": "',
                    Strings.toString(amount),
                    '"'
                )
            );
        } catch (bytes memory) {}
        if (stats[_token].observer != address(0)) {
            properties = string(
                abi.encodePacked(
                    properties,
                    ', "observer": "',
                    this.checksumEncode(
                        bytes(
                            Strings.toHexString(
                                uint160(stats[_token].observer),
                                20
                            )
                        )
                    ),
                    '"'
                )
            );
        }
        if (stats[_token].totalTaxP > 0) {
            properties = string(
                abi.encodePacked(
                    properties,
                    ', "taxDenominator": "',
                    Strings.toString(stats[_token].taxQ),
                    '", "totalTaxNumerator": "',
                    Strings.toString(stats[_token].totalTaxP),
                    '"'
                )
            );
        }
        if (stats[_token].reflectionTaxP > 0) {
            properties = string(
                abi.encodePacked(
                    properties,
                    ', "reflectionTaxNumerator": "',
                    Strings.toString(stats[_token].reflectionTaxP),
                    '"'
                )
            );
        }
        if (burners[_token].length > 0) {
            properties = string(
                abi.encodePacked(
                    properties,
                    ', "burnedAmount": "',
                    Strings.toString(getBurnAmount(_token)),
                    '"'
                )
            );
        }
        properties = string(abi.encodePacked(properties, "}"));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

library BonfireTokenHelper {
    string constant _totalSupply = "totalSupply()";
    string constant _circulatingSupply = "circulatingSupply()";
    string constant _token = "sourceToken()";
    string constant _wrapper = "wrapper()";
    bytes constant SUPPLY = abi.encodeWithSignature(_totalSupply);
    bytes constant CIRCULATING = abi.encodeWithSignature(_circulatingSupply);
    bytes constant TOKEN = abi.encodeWithSignature(_token);
    bytes constant WRAPPER = abi.encodeWithSignature(_wrapper);

    function circulatingSupply(address token)
        external
        view
        returns (uint256 supply)
    {
        (bool _success, bytes memory data) = token.staticcall(CIRCULATING);
        if (!_success) {
            (_success, data) = token.staticcall(SUPPLY);
        }
        if (_success) {
            supply = abi.decode(data, (uint256));
        }
    }

    function getSourceToken(address proxyToken)
        external
        view
        returns (address sourceToken)
    {
        (bool _success, bytes memory data) = proxyToken.staticcall(TOKEN);
        if (_success) {
            sourceToken = abi.decode(data, (address));
        }
    }

    function getWrapper(address proxyToken)
        external
        view
        returns (address wrapper)
    {
        (bool _success, bytes memory data) = proxyToken.staticcall(WRAPPER);
        if (_success) {
            wrapper = abi.decode(data, (address));
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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