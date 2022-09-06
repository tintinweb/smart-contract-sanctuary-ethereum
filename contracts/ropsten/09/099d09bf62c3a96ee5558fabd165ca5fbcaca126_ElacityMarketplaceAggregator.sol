// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./ElacityMulticall.sol";

interface INFTContract {
    function mint(address _beneficiary, string calldata _tokenUri)
        external
        payable
        returns (uint256);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool isOperator);

    function setApprovalForAll(address _operator, bool approved) external;
}

interface IMarketplace {
    function pipeRegisterRoyalty(
        address _nftAddress,
        uint256 _tokenId,
        uint16 _royalty
    ) external;

    function pipeListItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        uint256 _pricePerItem,
        uint256 _startingTime
    ) external;
}

interface IFactory {
    function exists(address) external view returns (bool);
}

interface IAuction {
    function pipeCreateAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        bool minBidReserve,
        uint256 _endTimestamp
    ) external;

    function pipeUpdateAuctionReservePrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice
    ) external;

    function pipeUpdateAuctionStartTime(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startTime
    ) external;

    function pipeUpdateAuctionEndTime(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _endTimestamp
    ) external;
}

interface IAddressRegistry {
    function artion() external view returns (address);

    function marketplace() external view returns (address);

    function auction() external view returns (address);

    function factory() external view returns (address);

    function privateFactory() external view returns (address);

    function artFactory() external view returns (address);

    function privateArtFactory() external view returns (address);
}

contract ElacityMarketplaceAggregator is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ElacityMulticall
{
    //bytes4 private constant SELECTOR_LIST_ITEM = 0x3fc1cc26;
    bytes4 private constant SELECTOR_LIST_ITEM = 0x035f3ebb;
    //bytes4 private constant SELECTOR_CREATE_AUCTION = 0xab2870e2;
    bytes4 private constant SELECTOR_CREATE_AUCTION = 0xc86b1af7;
    //bytes4 private constant SELECTOR_REGISTER_ROYALTY = 0xf3880b6e;
    bytes4 private constant SELECTOR_REGISTER_ROYALTY = 0x64070ca7;

    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    event Warning(address addr, string message);

    /// @notice Contract initializer
    function initialize(address _addressRegistry) public initializer {
        addressRegistry = IAddressRegistry(_addressRegistry);

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Check whether an address is supported
    function _isValidAddress(address addr) internal view returns (bool) {
        return
            addressRegistry.artion() == addr ||
            addressRegistry.marketplace() == addr ||
            addressRegistry.auction() == addr ||
            IFactory(addressRegistry.factory()).exists(addr) ||
            IFactory(addressRegistry.privateFactory()).exists(addr) ||
            IFactory(addressRegistry.artFactory()).exists(addr) ||
            IFactory(addressRegistry.privateArtFactory()).exists(addr);
    }

    /// @notice Check whether an address is a valid NFT contract address
    function _isValidNFTAddress(address addr) internal view returns (bool) {
        return
            addressRegistry.artion() == addr ||
            IFactory(addressRegistry.factory()).exists(addr) ||
            IFactory(addressRegistry.privateFactory()).exists(addr) ||
            IFactory(addressRegistry.artFactory()).exists(addr) ||
            IFactory(addressRegistry.privateArtFactory()).exists(addr);
    }

    function _requireApproval(
        address _nftAddress,
        address _owner,
        address _operator
    ) internal view {
        require(
            INFTContract(_nftAddress).isApprovedForAll(_owner, _operator),
            "sender is not approved for target"
        );
    }

    /**
     * @dev Mint and pipe another actions to the ElacityMulticall contract
     * @dev Note that when we send data into pipe call, we injected _tokenId as a placeholder
     * @dev So we need to parse the data and replace the placeholder with the real tokenId outputed by the mint function
     * @dev https://github.com/ethereum/solidity/issues/10382
     * @dev see also https://stackoverflow.com/questions/70693335/delegatecall-for-multi-transaction-for-minting-approving-and-putting-on-a-marke
     */
    function mintAndPipe(
        address _nftAddress,
        string calldata _tokenUri,
        Call[] calldata calls
    ) external payable returns (uint256 tokenId) {
        // verify _nftAddress is ERC721 contract and is supported in the platform
        require(_isValidNFTAddress(_nftAddress), "invalid NFT address");

        (bool minted, bytes memory mintResult) = payable(_nftAddress).call{
            value: msg.value
        }(
            abi.encodeWithSelector(
                INFTContract(_nftAddress).mint.selector,
                _msgSender(),
                _tokenUri
            )
        );
        require(minted, "Failed to mint token");

        // decode tokenId from mintResult
        tokenId = abi.decode(mintResult, (uint256));

        // now we will setup pipeline according to request
        // 1. register royalty
        // 2. list item OR create auction

        for (uint256 i = 0; i < calls.length; i++) {
            // only proceed when target address are trusted, otherwise we will skip and emit a warning
            if (_isValidAddress(calls[i].target)) {
                // for each calls parameter we will retrieve the method ID and arguments passed in
                bytes4 methodId = _getSelector(calls[i].data);
                if (
                    methodId == SELECTOR_REGISTER_ROYALTY &&
                    calls[i].target == addressRegistry.marketplace()
                ) {
                    // 1. register royalty
                    (address nftAddress, , uint16 royaltyValue) = abi.decode(
                        calls[i].data[4:],
                        (address, uint256, uint16)
                    );
                    if (royaltyValue > 0) {
                        // only process royalty registration when its value is greater than 0
                        IMarketplace(addressRegistry.marketplace())
                            .pipeRegisterRoyalty(
                                nftAddress,
                                tokenId,
                                royaltyValue
                            );
                    }
                } else if (
                    methodId == SELECTOR_CREATE_AUCTION &&
                    calls[i].target == addressRegistry.auction()
                ) {
                    // 2. create auction
                    _requireApproval(
                        _nftAddress,
                        _msgSender(),
                        calls[i].target
                    );
                    (
                        address nftAddress,
                        ,
                        address payToken,
                        uint256 pricePerItem,
                        uint256 startTime,
                        bool minBidReserve,
                        uint256 endTime
                    ) = abi.decode(
                            calls[i].data[4:],
                            (
                                address,
                                uint256,
                                address,
                                uint256,
                                uint256,
                                bool,
                                uint256
                            )
                        );
                    IAuction(addressRegistry.auction()).pipeCreateAuction(
                        nftAddress,
                        tokenId,
                        payToken,
                        pricePerItem,
                        startTime,
                        minBidReserve,
                        endTime
                    );
                } else if (
                    methodId == SELECTOR_LIST_ITEM &&
                    calls[i].target == addressRegistry.marketplace()
                ) {
                    // 2. list item
                    _requireApproval(
                        _nftAddress,
                        _msgSender(),
                        calls[i].target
                    );
                    (
                        address nftAddress,
                        ,
                        uint256 qt,
                        address payToken,
                        uint256 pricePerItem,
                        uint256 startTime
                    ) = abi.decode(
                            calls[i].data[4:],
                            (
                                address,
                                uint256,
                                uint256,
                                address,
                                uint256,
                                uint256
                            )
                        );
                    IMarketplace(addressRegistry.marketplace()).pipeListItem(
                        nftAddress,
                        tokenId,
                        qt,
                        payToken,
                        pricePerItem,
                        startTime
                    );
                } else {
                    // make normal call as sent by the user
                    (bool ok, bytes memory returndata) = calls[i].target.call(
                        calls[i].data
                    );
                    if (!ok) {
                        if (returndata.length > 0) {
                            assembly {
                                let returndata_sz := mload(returndata)
                                revert(add(32, returndata), returndata_sz)
                            }
                        } else {
                            revert("Failed to call target");
                        }
                    }
                }
            } else {
                emit Warning(calls[i].target, "unknown address, skipped");
            }
        }
    }

    /**
     @notice Update FantomAddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IAddressRegistry(_registry);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

contract ElacityMulticall {
    struct Call {
        address target;
        bytes data;
    }

    /**
     * method that check wether an address is a contract or not
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @notice call a set of contract methods and arguments sequentially in view mode
     */
    function multistaticcall(Call[] calldata calls)
        external
        view
        returns (bytes[] memory returnData)
    {
        returnData = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.staticcall(
                calls[i].data
            );
            require(success);
            returnData[i] = ret;
        }
    }

    /**
     * @notice call a set of contract methods and arguments sequentially
     */
    function multicall(Call[] calldata calls)
        external
        returns (bytes[] memory returnData)
    {
        returnData = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(
                calls[i].data
            );
            require(success);
            returnData[i] = ret;
        }
    }

    // https://github.com/InstaDApp/dsa-contracts/blob/7e70b926cb33263783f621612157f49f785daa0a/contracts/account.sol#L91
    function _delegateCall(address _target, bytes memory _data)
        internal
        returns (bool)
    {
        require(_isContract(_target), "invalid target");
        assembly {
            let succeeded := delegatecall(
                gas(),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())
            switch succeeded
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // @dev: get selector from call raw argument
    function _getSelector(bytes memory rawData)
        internal
        pure
        returns (bytes4 selector)
    {
        assembly {
            selector := mload(add(rawData, 32))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}