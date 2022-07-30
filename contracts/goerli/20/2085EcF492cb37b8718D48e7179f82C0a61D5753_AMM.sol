// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC1155MintBurn.sol";
import "./interfaces/IAMM.sol";

contract AMM is IAMM, Initializable {
    using SafeERC20 for IERC20;

    // todo: Change this interface
    IERC1155MintBurn public element;
    address public studio;
    uint256 public totalFeeNumerator;
    uint256 public artistFeeNumerator;
    uint256 constant FEE_DENOMINATOR = 1_000_000_000;
    uint256 public platformRevenue;

    // tokenID => BondingCurve
    mapping(uint256 => BondingCurve) public tokenIdToBondingCurve;
    mapping(address => uint256) public artistRevenues;

    modifier onlyStudio() {
        require(
            msg.sender == studio,
            "Only the Studio contract can call this function"
        );
        _;
    }

    function initialize(
        address _element,
        address _studio,
        uint256 _totalFeeNumerator,
        uint256 _artistFeeNumerator
    ) external initializer {
        element = IERC1155MintBurn(_element);
        studio = _studio;
        totalFeeNumerator = _totalFeeNumerator;
        artistFeeNumerator = _artistFeeNumerator;
    }

    function createBondingCurves(
        uint256[] calldata _tokenIds,
        uint256[] calldata _constantAs,
        uint256[] calldata _constantBs,
        address _artistAddress,
        address _erc20Token,
        uint256 _startTime
    ) external onlyStudio {
        require(
            _tokenIds.length == _constantAs.length &&
                _tokenIds.length == _constantBs.length,
            "Invalid array lengths"
        );
        for (uint256 i; i < _tokenIds.length; i++) {
            createBondingCurve(
                _tokenIds[i],
                _constantAs[i],
                _constantBs[i],
                _artistAddress,
                _erc20Token,
                _startTime
            );
        }
    }

    function createBondingCurve(
        uint256 _tokenId,
        uint256 _constantA,
        uint256 _constantB,
        address _artistAddress,
        address _erc20Token,
        uint256 _startTime
    ) public onlyStudio {
        require(
            _artistAddress != address(0),
            "Artist address cannot be address zero"
        );
        require(
            tokenIdToBondingCurve[_tokenId].artistAddress == address(0),
            "Bonding curve already initialized"
        );

        tokenIdToBondingCurve[_tokenId] = BondingCurve(
            _constantA,
            _constantB,
            0,
            _artistAddress,
            _erc20Token,
            _startTime
        );

        emit BondingCurveCreated(
            _tokenId,
            _constantA,
            _constantB,
            _artistAddress,
            _erc20Token,
            _startTime
        );
    }

    function buyElements(
        uint256 _tokenId,
        uint256 _erc1155Quantity,
        uint256 _maxERC20ToSpend,
        address _spender,
        address _recipient
    ) public onlyStudio {
        (
            uint256 erc20TotalAmount,
            uint256 erc20TotalFee,
            uint256 erc20ArtistFee
        ) = getBuyERC20AmountWithFee(_tokenId, _erc1155Quantity);

        require(erc20TotalAmount <= _maxERC20ToSpend, "Slippage too high");

        IERC20(tokenIdToBondingCurve[_tokenId].erc20Token).safeTransferFrom(
            _spender,
            address(this),
            erc20TotalAmount
        );
        // platformRevenue += erc20TotalFee - erc20ArtistFee;
        // artistRevenues[
        //     tokenIdToBondingCurve[_tokenId].artistAddress
        // ] += erc20ArtistFee;
        tokenIdToBondingCurve[_tokenId].reserves += (erc20TotalAmount -
            erc20TotalFee);

        element.mint(_recipient, _tokenId, _erc1155Quantity);

        // emit ElementsBought(
        //     _bondingCurveCreator,
        //     _tokenId,
        //     _erc1155Quantity,
        //     erc20TotalAmount,
        //     erc20TotalFee,
        //     erc20ArtistFee,
        //     _recipient
        // );
    }

    function batchBuyElements(
        uint256[] memory _tokenIds,
        uint256[] memory _erc1155Quantities,
        uint256[] memory _maxERC20sToSpend,
        address _spender,
        address _recipient
    ) external onlyStudio {
        require(
            _tokenIds.length == _erc1155Quantities.length &&
                _tokenIds.length == _maxERC20sToSpend.length,
            "Invalid array lengths"
        );

        for (uint256 i; i < _tokenIds.length; i++) {
            buyElements(
                _tokenIds[i],
                _erc1155Quantities[i],
                _maxERC20sToSpend[i],
                _spender,
                _recipient
            );
        }
    }

    function sellElements(
        uint256 _tokenId,
        uint256 _erc1155Quantity,
        uint256 _minERC20ToReceive,
        address _erc20Recipient
    ) public onlyStudio {
        require(
            block.timestamp >= tokenIdToBondingCurve[_tokenId].startTime,
            "AMM has not started yet"
        );
        uint256 erc20TotalAmount = getSellERC20Amount(
            _tokenId,
            _erc1155Quantity
        );
        require(erc20TotalAmount >= _minERC20ToReceive, "Slippage too high");

        tokenIdToBondingCurve[_tokenId].reserves -= erc20TotalAmount;

        element.burn(msg.sender, _tokenId, _erc1155Quantity);

        IERC20(tokenIdToBondingCurve[_tokenId].erc20Token).safeTransfer(
            _erc20Recipient,
            erc20TotalAmount
        );

        // emit ElementsSold(
        //     _bondingCurveCreator,
        //     _tokenId,
        //     _erc1155Quantity,
        //     erc20TotalAmount,
        //     _recipient
        // );
    }

    function batchSellElements(
        uint256[] memory _tokenIds,
        uint256[] memory _erc1155Quantities,
        uint256[] memory _minERC20sToReceive,
        address _erc20Recipient
    ) external onlyStudio {
        require(
            _tokenIds.length == _erc1155Quantities.length &&
                _tokenIds.length == _minERC20sToReceive.length,
            "Invalid array lengths"
        );

        for (uint256 i; i < _tokenIds.length; i++) {
            sellElements(
                _tokenIds[i],
                _erc1155Quantities[i],
                _minERC20sToReceive[i],
                _erc20Recipient
            );
        }
    }

    // function claimPlatformRevenue(address _recipient) external onlyOwner {
    //     uint256 _platformRevenue = platformRevenue;
    //     platformRevenue = 0;

    //     weth.transfer(_recipient, _platformRevenue);

    //     emit PlatformRevenueClaimed(_recipient, _platformRevenue);
    // }

    // function claimArtistRevenue(address _recipient) external {
    //     require(
    //         artistRevenues[msg.sender] > 0,
    //         "You do not have an available balance"
    //     );

    //     uint256 claimedRevenue = artistRevenues[msg.sender];
    //     artistRevenues[msg.sender] = 0;

    //     weth.safeTransfer(_recipient, claimedRevenue);

    //     emit ArtistRevenueClaimed(_recipient, claimedRevenue);
    // }

    function getBuyERC20AmountWithFee(
        uint256 _tokenId,
        uint256 _erc1155Quantity
    )
        public
        view
        returns (
            uint256 erc20TotalAmount,
            uint256 erc20TotalFee,
            uint256 erc20ArtistFee
        )
    {
        uint256 nominalERC20Amount = getBuyERC20Amount(
            _tokenId,
            _erc1155Quantity
        );
        erc20TotalFee =
            (nominalERC20Amount * totalFeeNumerator) /
            FEE_DENOMINATOR;
        erc20ArtistFee =
            (nominalERC20Amount * artistFeeNumerator) /
            FEE_DENOMINATOR;
        erc20TotalAmount = nominalERC20Amount + erc20TotalFee;
    }

    function getBuyERC20Amount(uint256 _tokenId, uint256 _erc1155Quantity)
        public
        view
        returns (uint256 erc20Amount)
    {
        require(
            block.timestamp >= tokenIdToBondingCurve[_tokenId].startTime,
            "AMM has not started yet"
        );
        require(
            tokenIdToBondingCurve[_tokenId].artistAddress != address(0),
            "Bonding curve not initialized"
        );

        // reserves = (a * supply) + (b * supply)^2
        uint256 newElementSupply = element.totalSupply(_tokenId) +
            _erc1155Quantity;

        erc20Amount =
            ((tokenIdToBondingCurve[_tokenId].constantA * newElementSupply) +
                (tokenIdToBondingCurve[_tokenId].constantB *
                    newElementSupply) **
                    2) -
            tokenIdToBondingCurve[_tokenId].reserves;
    }

    function getSellERC20Amount(uint256 _tokenId, uint256 _erc1155Quantity)
        public
        view
        returns (uint256 erc20Amount)
    {
        require(
            block.timestamp >= tokenIdToBondingCurve[_tokenId].startTime,
            "AMM has not started yet"
        );
        require(
            tokenIdToBondingCurve[_tokenId].artistAddress != address(0),
            "Bonding curve not initialized"
        );
        require(
            element.totalSupply(_tokenId) >= _erc1155Quantity,
            "Quantity greater than total supply"
        );
        // reserves = (a * supply) + (b * supply)^2
        uint256 newElementSupply = element.totalSupply(_tokenId) -
            _erc1155Quantity;

        erc20Amount =
            tokenIdToBondingCurve[_tokenId].reserves -
            ((tokenIdToBondingCurve[_tokenId].constantA * newElementSupply) +
                (tokenIdToBondingCurve[_tokenId].constantB *
                    newElementSupply) **
                    2);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC1155MintBurn {
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAMM {
    struct BondingCurve {
        uint256 constantA;
        uint256 constantB;
        uint256 reserves;
        address artistAddress;
        address erc20Token;
        uint256 startTime;
    }

    event BondingCurveCreated(
        uint256 indexed tokenId,
        uint256 constantA,
        uint256 constantB,
        address indexed artistAddress,
        address erc20Token,
        uint256 startTime
    );

    event ElementsBought(
        address indexed bondingCurveCreator,
        uint256 indexed tokenId,
        uint256 erc1155Quantity,
        uint256 erc20TotalSpent,
        uint256 erc20TotalFee,
        uint256 erc20ArtistFee,
        address indexed recipient
    );

    event ElementsSold(
        address indexed bondingCurveCreator,
        uint256 indexed tokenId,
        uint256 erc1155Quantity,
        uint256 erc20Received,
        address indexed recipient
    );

    event PlatformRevenueClaimed(
        address indexed recipient,
        uint256 revenueClaimed
    );

    event ArtistRevenueClaimed(
        address indexed recipient,
        uint256 revenueClaimed
    );

    function initialize(
        address _element,
        address _studio,
        uint256 _totalFeeNumerator,
        uint256 _artistFeeNumerator
    ) external;

    function createBondingCurves(
        uint256[] calldata _tokenIds,
        uint256[] calldata _constantAs,
        uint256[] calldata _constantBs,
        address _artistAddress,
        address _erc20Token,
        uint256 _startTime
    ) external;

    function createBondingCurve(
        uint256 _tokenId,
        uint256 _constantA,
        uint256 _constantB,
        address _artistAddress,
        address _erc20Token,
        uint256 _startTime
    ) external;

    function buyElements(
        uint256 _tokenId,
        uint256 _erc1155Quantity,
        uint256 _maxERC20ToSpend,
        address _spender,
        address _recipient
    ) external;

    function batchBuyElements(
        uint256[] memory _tokenIds,
        uint256[] memory _erc1155Quantities,
        uint256[] memory _maxERC20sToSpend,
        address _spender,
        address _recipient
    ) external;

    function sellElements(
        uint256 _tokenId,
        uint256 _erc1155Quantity,
        uint256 _minERC20ToReceive,
        address _erc20Recipient
    ) external;

    function batchSellElements(
        uint256[] memory _tokenIds,
        uint256[] memory _erc1155Quantities,
        uint256[] memory _minERC20sToReceive,
        address _erc20Recipient
    ) external;

    function getBuyERC20AmountWithFee(
        uint256 _tokenId,
        uint256 _erc1155Quantity
    )
        external
        view
        returns (
            uint256 erc20TotalAmount,
            uint256 erc20TotalFee,
            uint256 erc20ArtistFee
        );

    function getBuyERC20Amount(uint256 _tokenId, uint256 _erc1155Quantity)
        external
        view
        returns (uint256 erc20Amount);
    

    function getSellERC20Amount(uint256 _tokenId, uint256 _erc1155Quantity)
        external
        view
        returns (uint256 erc20Amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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