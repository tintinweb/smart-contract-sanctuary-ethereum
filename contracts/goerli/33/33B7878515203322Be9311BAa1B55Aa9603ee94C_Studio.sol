//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IStudio.sol";
import "./Marketplace.sol";
import "./StringConverter.sol";

contract Studio is IStudio, Marketplace, ERC721Holder, StringConverter {
    mapping(uint256 => CanvasData) public canvases;
    mapping(address => uint256) public userNonces;

    constructor(
        address _owner,
        address _canvas,
        address _element,
        uint256 _auctionStartDelay,
        string memory _baseURI
    ) {
        _transferOwnership(_owner);
        canvas = ICanvas(_canvas);
        element = IElement(_element);
        auctionStartDelay = _auctionStartDelay;
        baseURI = _baseURI;
    }

    function wrap(uint256 _projectId, uint256[] calldata _elementIndexes)
        public
        returns (uint256 _canvasTokenId)
    {
        require(
            _elementIndexes.length ==
                projects[_projectId].elementCategoryLabels.length,
            "S01"
        );

        if (
            canvas.getProjectSupply(_projectId) <
            canvas.getProjectMaxSupply(_projectId)
        ) {
            _canvasTokenId = canvas.mint(_projectId, msg.sender);
        } else {
            require(projects[_projectId].blankCanvasIds.length > 0, "S02");
            _canvasTokenId = projects[_projectId].blankCanvasIds[
                projects[_projectId].blankCanvasIds.length - 1
            ];
            projects[_projectId].blankCanvasIds.pop();
            canvas.safeTransferFrom(address(this), msg.sender, _canvasTokenId);
        }

        bytes32 newHash = keccak256(
            abi.encodePacked(msg.sender, userNonces[msg.sender])
        );

        canvases[_canvasTokenId].hash = newHash;

        uint256[] memory elementTokenIds = new uint256[](
            _elementIndexes.length
        );

        for (uint256 i; i < _elementIndexes.length; i++) {
            elementTokenIds[i] = projects[_projectId].elementTokenIds[i][
                _elementIndexes[i]
            ];

            element.safeTransferFrom(
                msg.sender,
                address(this),
                elementTokenIds[i],
                1,
                ""
            );
        }

        canvases[_canvasTokenId].wrapped = true;
        canvases[_canvasTokenId].wrappedElementTokenIds = elementTokenIds;
        userNonces[msg.sender]++;

        emit CanvasWrapped(_canvasTokenId, msg.sender);
    }

    function unwrap(uint256 _canvasId) public {
        require(msg.sender == canvas.ownerOf(_canvasId), "S03");
        require(canvases[_canvasId].wrapped, "S04");

        // Transfer elements to the user
        for (
            uint256 i;
            i < canvases[_canvasId].wrappedElementTokenIds.length;
            i++
        ) {
            element.safeTransferFrom(
                address(this),
                msg.sender,
                canvases[_canvasId].wrappedElementTokenIds[i],
                1,
                ""
            );
        }

        // Reset canvas state to blank canvas
        canvases[_canvasId].hash = 0;
        canvases[_canvasId].wrapped = false;
        canvases[_canvasId].wrappedElementTokenIds = new uint256[](0);

        // Transfer canvas from the user to this address
        canvas.safeTransferFrom(msg.sender, address(this), _canvasId);

        // Add the canvas ID to the array of blank canvses held by the studio
        projects[getProjectIdFromCanvasId(_canvasId)].blankCanvasIds.push(
            _canvasId
        );

        emit CanvasUnwrapped(_canvasId, msg.sender);
    }

    function buyElementsAndWrap(
        uint256 _projectId,
        uint256[] calldata _elementCategoryIndexesToBuy,
        uint256[] calldata _elementIndexesToBuy,
        uint256[] calldata _elementQuantitiesToBuy,
        uint256[] calldata _elementIndexesToWrap
    ) public {
        buyElements(
            _projectId,
            _elementCategoryIndexesToBuy,
            _elementIndexesToBuy,
            _elementQuantitiesToBuy
        );
        wrap(_projectId, _elementIndexesToWrap);
    }

    function getCanvasURI(uint256 _canvasTokenId)
        external
        view
        returns (string memory)
    {
        return string.concat(baseURI, toString(_canvasTokenId));
    }

    function getCanvasHash(uint256 _canvasId) external view returns (bytes32) {
        return canvases[_canvasId].hash;
    }

    function getCanvasElementLabels(uint256 _canvasId)
        external
        view
        returns (string[] memory elementLabels)
    {
        uint256 elementLabelsLength = canvases[_canvasId]
            .wrappedElementTokenIds
            .length;
        elementLabels = new string[](elementLabelsLength);

        for (uint256 i; i < elementLabelsLength; i++) {
            elementLabels[i] = element.getElementLabel(
                canvases[_canvasId].wrappedElementTokenIds[i]
            );
        }
    }

    function getCanvasElementValues(uint256 _canvasId)
        external
        view
        returns (string[] memory elementValues)
    {
        uint256 elementValuesLength = canvases[_canvasId]
            .wrappedElementTokenIds
            .length;
        elementValues = new string[](elementValuesLength);

        for (uint256 i; i < elementValuesLength; i++) {
            elementValues[i] = element.getElementValue(
                canvases[_canvasId].wrappedElementTokenIds[i]
            );
        }
    }

    function getIsCanvasWrapped(uint256 _canvasId)
        external
        view
        returns (bool)
    {
        return canvases[_canvasId].wrapped;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStudio {
    event CanvasWrapped(uint256 indexed canvasTokenId, address indexed wrapper);
    event CanvasUnwrapped(uint256 indexed canvasId, address indexed unwrapper);

    struct CanvasData {
        bool wrapped;
        uint256[] wrappedElementTokenIds;
        bytes32 hash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Projects.sol";
import "./interfaces/IMarketplace.sol";

abstract contract Marketplace is IMarketplace, Projects, ERC1155Holder {
    using SafeERC20 for IERC20;

    uint256 public constant auctionPlatformFeeNumerator = 100_000_000;
    uint256 public constant FEE_DENOMINATOR = 1_000_000_000;
    uint256 public auctionStartDelay;

    mapping(address => mapping(address => uint256))
        public artistClaimableRevenues; // Artist address => ERC-20 address => Amount
    mapping(address => uint256) public platformClaimableRevenues; // ERC-20 address => Revenue amount

    function buyElements(
        uint256 _projectId,
        uint256[] calldata _elementCategoryIndexes,
        uint256[] calldata _elementIndexes,
        uint256[] calldata _elementQuantities
    ) public {
        require(
            _elementCategoryIndexes.length == _elementIndexes.length,
            "M01"
        );
        require(
            _elementCategoryIndexes.length == _elementQuantities.length,
            "M01"
        );

        uint256 totalQuantity;

        for (uint256 i; i < _elementCategoryIndexes.length; i++) {
            uint256 elementTokenId = projects[_projectId].elementTokenIds[
                _elementCategoryIndexes[i]
            ][_elementIndexes[i]];
            require(
                element.balanceOf(address(this), elementTokenId) >=
                    _elementQuantities[i],
                "M02"
            );

            totalQuantity += _elementQuantities[i];
            element.safeTransferFrom(
                address(this),
                msg.sender,
                elementTokenId,
                _elementQuantities[i],
                ""
            );
        }

        uint256 erc20Amount = totalQuantity *
            getProjectElementAuctionPrice(_projectId);

        address auctionERC20 = projects[_projectId].auctionERC20;

        IERC20(auctionERC20).transferFrom(
            msg.sender,
            address(this),
            erc20Amount
        );

        uint256 platformRevenue = (erc20Amount * auctionPlatformFeeNumerator) /
            FEE_DENOMINATOR;
        platformClaimableRevenues[auctionERC20] += platformRevenue;
        artistClaimableRevenues[projects[_projectId].artistAddress][
            auctionERC20
        ] += erc20Amount - platformRevenue;

        emit ElementBought(
            msg.sender,
            _projectId,
            _elementCategoryIndexes,
            _elementIndexes,
            _elementQuantities
        );
    }

    function scheduleAuction(
        uint256 _projectId,
        address _auctionERC20,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice
    ) external onlyAdmin {
        require(projects[_projectId].locked, "M03");
        require(
            _auctionStartTime >= block.timestamp + auctionStartDelay,
            "M03"
        );
        require(_auctionEndTime >= _auctionStartTime, "M05");
        require(_auctionEndPrice <= _auctionStartPrice, "M06");

        projects[_projectId].auctionERC20 = _auctionERC20;
        projects[_projectId].auctionStartTime = _auctionStartTime;
        projects[_projectId].auctionEndTime = _auctionEndTime;
        projects[_projectId].auctionStartPrice = _auctionStartPrice;
        projects[_projectId].auctionEndPrice = _auctionEndPrice;

        emit AuctionScheduled(
            _projectId,
            _auctionERC20,
            _auctionStartTime,
            _auctionEndTime,
            _auctionStartPrice,
            _auctionEndPrice
        );
    }

    function updateAuctionStartDelay(uint256 _auctionStartDelay)
        external
        onlyOwner
    {
        auctionStartDelay = _auctionStartDelay;

        emit AuctionStartDelayUpdated(_auctionStartDelay);
    }

    function claimPlatformRevenue(address _token) external onlyOwner {
        uint256 claimedRevenue = platformClaimableRevenues[_token];
        require(claimedRevenue > 0, "M07");

        platformClaimableRevenues[_token] = 0;

        IERC20(_token).safeTransfer(msg.sender, claimedRevenue);

        emit PlatformRevenueClaimed(msg.sender, _token, claimedRevenue);
    }

    function claimArtistRevenue(address _token) external {
        uint256 claimedRevenue = artistClaimableRevenues[msg.sender][_token];
        require(claimedRevenue > 0, "M07");

        artistClaimableRevenues[msg.sender][_token] = 0;

        IERC20(_token).safeTransfer(msg.sender, claimedRevenue);

        emit ArtistRevenueClaimed(msg.sender, _token, claimedRevenue);
    }

    function getProjectElementAuctionPrice(uint256 _projectId)
        public
        view
        returns (uint256 _price)
    {
        require(
            block.timestamp >= projects[_projectId].auctionStartTime,
            "Auction hasn't started yet"
        );
        if (block.timestamp > projects[_projectId].auctionEndTime) {
            // Auction has ended
            _price = projects[_projectId].auctionEndPrice;
        } else {
            // Auction is active
            _price =
                projects[_projectId].auctionStartPrice -
                (
                    (((block.timestamp -
                        projects[_projectId].auctionStartTime) *
                        (projects[_projectId].auctionStartPrice -
                            projects[_projectId].auctionEndPrice)) /
                        (projects[_projectId].auctionEndTime -
                            projects[_projectId].auctionStartTime))
                );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract StringConverter {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICanvas.sol";
import "./interfaces/IElement.sol";
import "./interfaces/IProjects.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Projects is IProjects, Ownable {
    event ProjectCreated(uint256 projectId);
    
    ICanvas public canvas;
    IElement public element;
    string public baseURI;

    mapping(address => bool) internal admins;
    mapping(uint256 => ProjectData) internal projects;

    modifier onlyAdmin {
        require(
            admins[msg.sender],
            "P01"
        );
        _;
    }

    modifier notLocked(uint256 _projectId) {
        require(
            !projects[_projectId].locked,
            "P02"
        );
        _;
    }

    function createProject(
        address _artistAddress,
        uint256 _maxSupply,
        string memory _metadata,
        string[] memory _elementCategoryLabels,
        string[] memory _elementCategoryValues,
        string[][] memory _elementLabels,
        string[][] memory _elementValues,
        uint256[][][] memory _elementAmounts,
        address[] calldata _recipients
    ) external onlyAdmin {
        uint256 projectId = canvas.createProject(address(this), _maxSupply);

        projects[projectId].artistAddress = _artistAddress;
        projects[projectId].metadata = _metadata;
        projects[projectId].elementCategoryLabels = _elementCategoryLabels;
        projects[projectId].elementCategoryValues = _elementCategoryValues;
        projects[projectId].elementTokenIds = element.createElements2D(
            _elementLabels,
            _elementValues,
            _elementAmounts,
            _recipients
        );

        emit ProjectCreated(projectId);
    }

    function createAndUpdateElements(
        uint256 _projectId,
        uint256[] calldata _elementCategoryIndexes,
        uint256[] calldata _elementIndexes,
        string[] memory _elementLabels,
        string[] memory _elementValues,
        uint256[][] calldata _elementAmounts,
        address[] calldata _elementRecipients
    ) external onlyAdmin notLocked(_projectId) {
        require(_elementCategoryIndexes.length == _elementIndexes.length, "P03");
        require(_elementCategoryIndexes.length == _elementLabels.length, "P03");

        updateElements(
            _projectId,
            _elementCategoryIndexes,
            _elementIndexes,
            element.createElements(
            _elementLabels,
            _elementValues,
            _elementAmounts,
            _elementRecipients
        )
        );
    }

    function updateElements(
        uint256 _projectId,
        uint256[] calldata _elementCategoryIndexes,
        uint256[] calldata _elementIndexes,
        uint256[] memory _elementTokenIds
    ) public onlyAdmin notLocked(_projectId) {
        for (uint256 i; i < _elementCategoryIndexes.length; i++) {
            projects[_projectId].elementTokenIds[_elementCategoryIndexes[i]][
                    _elementIndexes[i]
                ] = _elementTokenIds[i];
        }
    }

    function updateMetadata(uint256 _projectId, string calldata _metadata)
        external
        onlyAdmin notLocked(_projectId)
    {
        projects[_projectId].metadata = _metadata;
    }

    function updateScript(
        uint256 _projectId,
        uint256 _scriptIndex,
        string calldata _script
    ) external onlyAdmin notLocked(_projectId) {
        projects[_projectId].scripts[_scriptIndex] = (_script);
    }

    function updateElementCategories(
        uint256 _projectId,
        string[] memory _elementCategoryLabels,
        string[] memory _elementCategoryValues
    ) external onlyAdmin notLocked(_projectId) {
        require(
            _elementCategoryLabels.length == _elementCategoryValues.length,
            "P04"
        );

        projects[_projectId].elementCategoryLabels = _elementCategoryLabels;
        projects[_projectId].elementCategoryValues = _elementCategoryValues;
    }

    function lockProject(uint256 _projectId)
        external
        onlyAdmin notLocked(_projectId) 
    {
        require(
            projects[_projectId].elementCategoryLabels.length ==
                projects[_projectId].elementTokenIds.length,
            "P03"
        );

        projects[_projectId].locked = true;
    }

    function updateBaseURI(string calldata _baseURI) external onlyOwner {
      baseURI = _baseURI;
    }

    function addAdmins(address[] calldata _admins)
        external
        onlyOwner
    {
        for (uint256 i; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
    }

    function removeAdmins(address[] calldata _admins)
        external
        onlyOwner
    {
        for (uint256 i; i < _admins.length; i++) {
            admins[_admins[i]] = false;
        }
    }

    function getProjectIsLocked(uint256 _projectId) external view returns (bool) {
      return projects[_projectId].locked;
    }
    
    function getProjectArtist(uint256 _projectId) external view returns (address) {
      return projects[_projectId].artistAddress;
    }

    function getProjectScripts(uint256 _projectId)
        external
        view
        returns (string[] memory _scripts)
    {
        uint256 scriptCount = getProjectScriptCount(_projectId);
        _scripts = new string[](scriptCount);

        for(uint256 i; i < scriptCount; i++) {
          _scripts[i] = projects[_projectId].scripts[i];
        }
    }

    function getProjectScriptCount(uint256 _projectId) public view returns (uint256) {
      uint256 scriptIndex;

      while(keccak256(abi.encodePacked(projects[_projectId].scripts[scriptIndex])) != keccak256(abi.encodePacked(""))) {
        scriptIndex++;
      }

      return scriptIndex;
    }

    function getProjectElementCategoryLabels(uint256 _projectId) external view returns (string[] memory) {
      return projects[_projectId].elementCategoryLabels;
    }

    function getProjectElementCategoryValues(uint256 _projectId) external view returns (string[] memory) {
      return projects[_projectId].elementCategoryValues;
    }

    function getProjectElementTokenIds(uint256 _projectId) external view returns (uint256[][] memory) {
      return projects[_projectId].elementTokenIds;
    }

    function getProjectMetadata(uint256 _projectId) external view returns (string memory) {
      return projects[_projectId].metadata;
    }

    function getIsAdmins(address _admin) external view returns (bool) {
      return admins[_admin];
    }

    function getProjectElementLabels(uint256 _projectId)
        public
        view
        returns (string[][] memory elementLabels)
    {
        uint256 elementCategoryLength = projects[_projectId]
            .elementCategoryLabels
            .length;
        elementLabels = new string[][](elementCategoryLength);

        for (uint256 i; i < elementCategoryLength; i++) {
            uint256 innerElementsLength = projects[_projectId]
                .elementTokenIds[i]
                .length;
            string[] memory innerElementLabels = new string[](innerElementsLength);
            for (uint256 j; j < innerElementsLength; j++) {
                innerElementLabels[j] = element.getElementLabel(
                    projects[_projectId].elementTokenIds[i][j]
                );
            }
            elementLabels[i] = innerElementLabels;
        }
    }

    function getProjectElementValues(uint256 _projectId)
        public
        view
        returns (string[][] memory elementValues)
    {
        uint256 elementCategoryLength = projects[_projectId]
            .elementCategoryLabels
            .length;
        elementValues = new string[][](elementCategoryLength);

        for (uint256 i; i < elementCategoryLength; i++) {
            uint256 innerElementsLength = projects[_projectId]
                .elementTokenIds[i]
                .length;
            string[] memory innerElementValues = new string[](innerElementsLength);
            for (uint256 j; j < innerElementsLength; j++) {
                innerElementValues[j] = element.getElementValue(
                    projects[_projectId].elementTokenIds[i][j]
                );
            }
            elementValues[i] = innerElementValues;
        }
    }

    function getProjectIdFromCanvasId(uint256 canvasId)
        public
        pure
        returns (uint256 projectId)
    {
        projectId = canvasId / 1_000_000;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplace {
    event AuctionScheduled(
        uint256 indexed projectId,
        address auctionERC20,
        uint256 auctionStartTime,
        uint256 auctionEndTime,
        uint256 auctionStartPrice,
        uint256 auctionEndPrice
    );
    event AuctionStartDelayUpdated(uint256 auctionStartDelay);
    event ElementBought(
        address indexed buyer,
        uint256 _projectId,
        uint256[] elementCategoryIndexes,
        uint256[] elementIndexes,
        uint256[] elementQuantities
    );
    event PlatformRevenueClaimed(
        address indexed claimer,
        address indexed token,
        uint256 claimedRevenue
    );
    event ArtistRevenueClaimed(
        address indexed artist,
        address indexed token,
        uint256 claimedRevenue
    );
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICanvas {
    function initialize(address _owner) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function createProject(
        address _studio,
        uint256 _maxSupply
    ) external returns (uint256 projectId);

    function mint(uint256 _projectId, address _to)
       external returns (uint256 _tokenId);

    function getProjectIdFromCanvasId(uint256 canvasId)
        external
        pure
        returns (uint256 projectId);

    function getProjectMaxSupply(uint256 _projectId) external view returns (uint256);

    function getProjectSupply(uint256 _projectId) external view returns (uint256);

    event MintedToken(address receiver, uint256 projectid, uint256 tokenId);
    event WrappedTokens(uint256 canvasId, uint256 tokenIds, uint256 amounts);
    event UnWrappedTokens(uint256 canvasId, uint256 tokenIds, uint256 amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElement {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function createElement(
        string calldata _label,
        string calldata _value,
        uint256[] calldata _amounts,
        address[] calldata _recipients
    ) external returns (uint256 tokenId);

    function createElements(
        string[] calldata _labels,
        string[] calldata _values,
        uint256[][] calldata _amounts,
        address[] calldata _recipients
    ) external returns (uint256[] memory tokenIds);

    function createElements2D(
        string[][] calldata _labels,
        string[][] calldata _values,
        uint256[][][] calldata _amounts,
        address[] calldata _recipients
    ) external returns (uint256[][] memory tokenIds);

    function getElementLabel(uint256 _tokenId)
        external
        view
        returns (string memory);

    function getElementValue(uint256 _tokenId)
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProjects {
    struct ProjectData {
        bool locked;
        address artistAddress;
        mapping(uint256 => string) scripts;
        string[] elementCategoryLabels;
        string[] elementCategoryValues;
        uint256[][] elementTokenIds;
        uint256[] blankCanvasIds;
        string metadata;
        address auctionERC20;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 auctionStartPrice;
        uint256 auctionEndPrice;
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