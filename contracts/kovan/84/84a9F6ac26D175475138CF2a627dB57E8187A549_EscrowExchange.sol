// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import './interfaces/IEscrowExchange.sol';

contract EscrowExchange is
    IEscrowExchange,
    Ownable,
    Pausable,
    ERC721Holder,
    ERC1155Holder
{
    using SafeERC20 for IERC20;
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.UintSet;

    ////////////////////////////////////////////////////////////////////////////
    // STATE
    ////////////////////////////////////////////////////////////////////////////

    /// @notice token => is whitelisted
    mapping(address => bool) public isWhitelistedTokens;

    /// @notice ExchangeRequest indexer
    uint256 private exchangeRequestCounter;
    /// @notice not whitelisted request indexes
    EnumerableSet.UintSet private notWhitelistedRequestIds;
    /// @notice whitelisted executor => request indexes
    mapping(address => EnumerableSet.UintSet)
        private whitelistedExecutorsRequestIds;
    /// @notice requester => request indexes
    mapping(address => EnumerableSet.UintSet) private myRequestIds;

    /// @notice index => requester (index > 0)
    mapping(uint256 => address) public exchangeRequester;
    /// @notice index => have assets (index > 0)
    mapping(uint256 => address[]) public exchangeHaveAssets;
    /// @notice index => have assets params (index > 0)
    mapping(uint256 => bytes[]) public exchangeHaveAssetsParams;
    /// @notice index => want assets (index > 0)
    mapping(uint256 => address[]) public exchangeWantAssets;
    /// @notice index => want assets params (index > 0)
    mapping(uint256 => bytes[]) public exchangeWantAssetsParams;

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event ExchangeRequestCreated(
        address indexed requester,
        uint256 indexed requestId,
        address[] haveAssets,
        bytes[] haveAssetsParams,
        address[] wantAssets,
        bytes[] wantAssetsParams,
        address[] whitelistedExecutors
    );
    event ExchangeRequestExecuted(
        address indexed requester,
        uint256 indexed requestId,
        address indexed executor,
        address[] haveAssets,
        bytes[] haveAssetsParams,
        address[] wantAssets,
        bytes[] wantAssetsParams
    );
    event ExchangeRequestCancelled(
        address indexed requester,
        uint256 indexed requestId,
        address[] haveAssets,
        bytes[] haveAssetsParams
    );

    ////////////////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////////////////

    constructor(address[] memory whitelistedTokens) {
        uint256 length = whitelistedTokens.length;

        for (uint256 i = 0; i < length; i++) {
            isWhitelistedTokens[whitelistedTokens[i]] = true;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // Modifier
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev if tokens are whitelisted
     * @param _tokens tokens addresses
     */
    modifier onlyWhitelistedTokens(address[] memory _tokens) {
        uint256 length = _tokens.length;
        require(length > 0, 'no tokens');

        for (uint256 i = 0; i < length; i++) {
            require(isWhitelistedTokens[_tokens[i]], 'not whitelisted token');
        }

        _;
    }

    /**
     * @dev if executor is whitelisted
     * @param _requestId exchange request id
     */
    modifier onlyWhitelistedExecutor(uint256 _requestId) {
        require(
            notWhitelistedRequestIds.contains(_requestId) ||
                whitelistedExecutorsRequestIds[msg.sender].contains(_requestId),
            'not whitelisted executor'
        );

        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    /// ADMIN
    ////////////////////////////////////////////////////////////////////////////

    function pause() external onlyOwner whenNotPaused {
        return _pause();
    }

    function unpause() external onlyOwner whenPaused {
        return _unpause();
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice create a new exchange request
     * @dev deposit have assets
     * @param _haveAssets have assets addresses
     * @param _haveAssetsParams have assets id/amount
     * @param _wantAssets want assets addresses
     * @param _wantAssetsParams want assets id/amount
     */
    function createExchangeRequest(
        address[] memory _haveAssets,
        bytes[] memory _haveAssetsParams,
        address[] memory _wantAssets,
        bytes[] memory _wantAssetsParams,
        address[] memory _whitelistedExecutors
    )
        external
        override
        onlyWhitelistedTokens(_haveAssets)
        onlyWhitelistedTokens(_wantAssets)
    {
        uint256 i;
        uint256 haveLength = _haveAssets.length;
        uint256 wantLength = _wantAssets.length;
        require(
            haveLength == _haveAssetsParams.length &&
                wantLength == _wantAssetsParams.length,
            'invalid length'
        );

        // create exchange request
        {
            exchangeRequestCounter += 1;

            // myRequestIds & exchangeRequester
            myRequestIds[msg.sender].add(exchangeRequestCounter);
            exchangeRequester[exchangeRequestCounter] = msg.sender;

            // haveAssets & haveAssetsParams
            for (i = 0; i < haveLength; i++) {
                exchangeHaveAssets[exchangeRequestCounter].push(_haveAssets[i]);
                exchangeHaveAssetsParams[exchangeRequestCounter].push(
                    _haveAssetsParams[i]
                );
            }

            // wantAssets & wantAssetsParams
            for (i = 0; i < wantLength; i++) {
                exchangeWantAssets[exchangeRequestCounter].push(_wantAssets[i]);
                exchangeWantAssetsParams[exchangeRequestCounter].push(
                    _wantAssetsParams[i]
                );
            }

            // notWhitelistedRequestIds & whitelistedExecutorsRequestIds
            uint256 whitelistedExecutorsLength = _whitelistedExecutors.length;
            if (whitelistedExecutorsLength > 0) {
                for (i = 0; i < whitelistedExecutorsLength; i++) {
                    whitelistedExecutorsRequestIds[_whitelistedExecutors[i]]
                        .add(exchangeRequestCounter);
                }
            } else {
                notWhitelistedRequestIds.add(exchangeRequestCounter);
            }
        }

        // deposit have assets
        {
            for (i = 0; i < haveLength; i++) {
                address haveAsset = _haveAssets[i];
                bytes memory haveAssetParam = _haveAssetsParams[i];

                // ERC20
                if (haveAsset.supportsInterface(type(IERC20).interfaceId)) {
                    uint256 amount = abi.decode(haveAssetParam, (uint256));
                    require(amount > 0, 'invalid amount');

                    IERC20(haveAsset).safeTransferFrom(
                        msg.sender,
                        address(this),
                        amount
                    );
                }
                // ERC721
                else if (
                    haveAsset.supportsInterface(type(IERC721).interfaceId)
                ) {
                    uint256 tokenId = abi.decode(haveAssetParam, (uint256));

                    IERC721(haveAsset).safeTransferFrom(
                        msg.sender,
                        address(this),
                        tokenId
                    );
                }
                // ERC1155
                else if (
                    haveAsset.supportsInterface(type(IERC1155).interfaceId)
                ) {
                    (uint256 id, uint256 amount) = abi.decode(
                        haveAssetParam,
                        (uint256, uint256)
                    );
                    require(amount > 0, 'invalid amount');

                    IERC1155(haveAsset).safeTransferFrom(
                        msg.sender,
                        address(this),
                        id,
                        amount,
                        ''
                    );
                }
            }
        }

        // event
        emit ExchangeRequestCreated(
            msg.sender,
            exchangeRequestCounter,
            _haveAssets,
            _haveAssetsParams,
            _wantAssets,
            _wantAssetsParams,
            _whitelistedExecutors
        );
    }

    /**
     * @notice execute exchange request
     * @dev deposit want assets and withdraw have assets
     * @param _requestId exchange request id
     */
    function executeExchangeRequest(uint256 _requestId)
        external
        override
        onlyWhitelistedExecutor(_requestId)
    {
        address requester = exchangeRequester[_requestId];
        require(requester != address(0), 'invalid request');

        address[] memory haveAssets = exchangeHaveAssets[_requestId];
        bytes[] memory haveAssetsParams = exchangeHaveAssetsParams[_requestId];
        address[] memory wantAssets = exchangeWantAssets[_requestId];
        bytes[] memory wantAssetsParams = exchangeWantAssetsParams[_requestId];

        uint256 i;
        uint256 haveLength = haveAssets.length;
        uint256 wantLength = wantAssets.length;

        // clear exchange request
        delete exchangeRequester[_requestId];
        delete exchangeHaveAssets[_requestId];
        delete exchangeHaveAssetsParams[_requestId];
        delete exchangeWantAssets[_requestId];
        delete exchangeWantAssetsParams[_requestId];
        notWhitelistedRequestIds.remove(_requestId);
        whitelistedExecutorsRequestIds[msg.sender].remove(_requestId);
        myRequestIds[requester].remove(_requestId);

        // deposit want assets
        {
            for (i = 0; i < wantLength; i++) {
                address wantAsset = wantAssets[i];
                bytes memory wantAssetParam = wantAssetsParams[i];

                // ERC20
                if (wantAsset.supportsInterface(type(IERC20).interfaceId)) {
                    uint256 amount = abi.decode(wantAssetParam, (uint256));
                    require(amount > 0, 'invalid amount');

                    IERC20(wantAsset).safeTransferFrom(
                        msg.sender,
                        address(this),
                        amount
                    );
                }
                // ERC721
                else if (
                    wantAsset.supportsInterface(type(IERC721).interfaceId)
                ) {
                    uint256 tokenId = abi.decode(wantAssetParam, (uint256));

                    IERC721(wantAsset).safeTransferFrom(
                        msg.sender,
                        address(this),
                        tokenId
                    );
                }
                // ERC1155
                else if (
                    wantAsset.supportsInterface(type(IERC1155).interfaceId)
                ) {
                    (uint256 id, uint256 amount) = abi.decode(
                        wantAssetParam,
                        (uint256, uint256)
                    );
                    require(amount > 0, 'invalid amount');

                    IERC1155(wantAsset).safeTransferFrom(
                        msg.sender,
                        address(this),
                        id,
                        amount,
                        ''
                    );
                }
            }
        }

        // withdraw have assets
        {
            for (i = 0; i < haveLength; i++) {
                address haveAsset = haveAssets[i];
                bytes memory haveAssetParam = haveAssetsParams[i];

                // ERC20
                if (haveAsset.supportsInterface(type(IERC20).interfaceId)) {
                    uint256 amount = abi.decode(haveAssetParam, (uint256));
                    require(amount > 0, 'invalid amount');

                    IERC20(haveAsset).safeTransfer(msg.sender, amount);
                }
                // ERC721
                else if (
                    haveAsset.supportsInterface(type(IERC721).interfaceId)
                ) {
                    uint256 tokenId = abi.decode(haveAssetParam, (uint256));

                    IERC721(haveAsset).safeTransferFrom(
                        address(this),
                        msg.sender,
                        tokenId
                    );
                }
                // ERC1155
                else if (
                    haveAsset.supportsInterface(type(IERC1155).interfaceId)
                ) {
                    (uint256 id, uint256 amount) = abi.decode(
                        haveAssetParam,
                        (uint256, uint256)
                    );
                    require(amount > 0, 'invalid amount');

                    IERC1155(haveAsset).safeTransferFrom(
                        address(this),
                        msg.sender,
                        id,
                        amount,
                        ''
                    );
                }
            }
        }

        // event
        emit ExchangeRequestExecuted(
            requester,
            _requestId,
            msg.sender,
            haveAssets,
            haveAssetsParams,
            wantAssets,
            wantAssetsParams
        );
    }

    /**
     * @notice cancel exchange request
     * @dev withdraw have assets
     * @param _requestId exchange request id
     */
    function cancelExchangeRequest(uint256 _requestId) external override {
        require(exchangeRequester[_requestId] == msg.sender, 'not requester');

        address[] memory haveAssets = exchangeHaveAssets[_requestId];
        bytes[] memory haveAssetsParams = exchangeHaveAssetsParams[_requestId];

        uint256 haveLength = haveAssets.length;

        // clear exchange request
        delete exchangeRequester[_requestId];
        delete exchangeHaveAssets[_requestId];
        delete exchangeHaveAssetsParams[_requestId];
        delete exchangeWantAssets[_requestId];
        delete exchangeWantAssetsParams[_requestId];
        notWhitelistedRequestIds.remove(_requestId);
        myRequestIds[msg.sender].remove(_requestId);

        // withdraw have assets
        {
            for (uint256 i = 0; i < haveLength; i++) {
                address haveAsset = haveAssets[i];
                bytes memory haveAssetParam = haveAssetsParams[i];

                // ERC20
                if (haveAsset.supportsInterface(type(IERC20).interfaceId)) {
                    uint256 amount = abi.decode(haveAssetParam, (uint256));
                    require(amount > 0, 'invalid amount');

                    IERC20(haveAsset).safeTransfer(msg.sender, amount);
                }
                // ERC721
                else if (
                    haveAsset.supportsInterface(type(IERC721).interfaceId)
                ) {
                    uint256 tokenId = abi.decode(haveAssetParam, (uint256));

                    IERC721(haveAsset).safeTransferFrom(
                        address(this),
                        msg.sender,
                        tokenId
                    );
                }
                // ERC1155
                else if (
                    haveAsset.supportsInterface(type(IERC1155).interfaceId)
                ) {
                    (uint256 id, uint256 amount) = abi.decode(
                        haveAssetParam,
                        (uint256, uint256)
                    );
                    require(amount > 0, 'invalid amount');

                    IERC1155(haveAsset).safeTransferFrom(
                        address(this),
                        msg.sender,
                        id,
                        amount,
                        ''
                    );
                }
            }
        }

        // event
        emit ExchangeRequestCancelled(
            msg.sender,
            _requestId,
            haveAssets,
            haveAssetsParams
        );
    }

    ////////////////////////////////////////////////////////////////////////////
    // VIEW
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice return all exchange offers
     * @dev not whitelisted exchange requests
     * @param _offset index offset
     * @param _size return size
     */
    function allExchangeOffers(uint256 _offset, uint256 _size)
        external
        view
        returns (
            uint256[] memory requestIds,
            address[][] memory haveAssets,
            bytes[][] memory haveAssetsParams,
            address[][] memory wantAssets,
            bytes[][] memory wantAssetsParams
        )
    {
        uint256 length = Math.min(
            notWhitelistedRequestIds.length() - _offset,
            _size
        );

        if (length > 0) {
            // initialize the length
            {
                requestIds = new uint256[](length);
                haveAssets = new address[][](length);
                haveAssetsParams = new bytes[][](length);
                wantAssets = new address[][](length);
                wantAssetsParams = new bytes[][](length);
            }

            uint256 i;
            uint256 j;

            for (i = 0; i < length; i++) {
                uint256 requestId = notWhitelistedRequestIds.at(i + _offset);

                // requestIds
                requestIds[i] = requestId;

                // haveAssets & haveAssetsParams
                {
                    uint256 haveLength = exchangeHaveAssets[requestId].length;

                    haveAssets[i] = new address[](haveLength);
                    haveAssetsParams[i] = new bytes[](haveLength);
                    for (j = 0; j < haveLength; j++) {
                        haveAssets[i][j] = exchangeHaveAssets[requestId][j];
                        haveAssetsParams[i][j] = exchangeHaveAssetsParams[
                            requestId
                        ][j];
                    }
                }

                // wantAssets & wantAssetsParams
                {
                    uint256 wantLength = exchangeWantAssets[requestId].length;

                    wantAssets[i] = new address[](wantLength);
                    wantAssetsParams[i] = new bytes[](wantLength);
                    for (j = 0; j < wantLength; j++) {
                        wantAssets[i][j] = exchangeWantAssets[requestId][j];
                        wantAssetsParams[i][j] = exchangeWantAssetsParams[
                            requestId
                        ][j];
                    }
                }
            }
        }
    }

    /**
     * @notice return whitelisted exchange offers
     * @dev whitelisted exchange requests for an executor
     * @param _executor executor address
     * @param _offset index offset
     * @param _size return size
     */
    function yourExchangeOffers(
        address _executor,
        uint256 _offset,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory requestIds,
            address[][] memory haveAssets,
            bytes[][] memory haveAssetsParams,
            address[][] memory wantAssets,
            bytes[][] memory wantAssetsParams
        )
    {
        EnumerableSet.UintSet
            storage _whitelistedExecutorsRequestIds = whitelistedExecutorsRequestIds[
                _executor
            ];
        uint256 maxLength = _whitelistedExecutorsRequestIds.length();

        uint256 i;
        uint256 length;

        for (i = _offset; i < maxLength && length <= _size; i++) {
            uint256 requestId = _whitelistedExecutorsRequestIds.at(i);

            if (exchangeRequester[requestId] != address(0)) {
                length += 1;
            }
        }

        if (length > 0) {
            // initialize the length
            {
                requestIds = new uint256[](length);
                haveAssets = new address[][](length);
                haveAssetsParams = new bytes[][](length);
                wantAssets = new address[][](length);
                wantAssetsParams = new bytes[][](length);
            }

            uint256 j;
            uint256 k;

            for (i = _offset; j < length; i++) {
                uint256 requestId = _whitelistedExecutorsRequestIds.at(i);

                if (exchangeRequester[requestId] != address(0)) {
                    // requestIds
                    requestIds[j] = requestId;

                    // haveAssets & haveAssetsParams
                    {
                        uint256 haveLength = exchangeHaveAssets[requestId]
                            .length;

                        haveAssets[j] = new address[](haveLength);
                        haveAssetsParams[j] = new bytes[](haveLength);
                        for (k = 0; k < haveLength; k++) {
                            haveAssets[j][k] = exchangeHaveAssets[requestId][k];
                            haveAssetsParams[j][k] = exchangeHaveAssetsParams[
                                requestId
                            ][k];
                        }
                    }

                    // wantAssets & wantAssetsParams
                    {
                        uint256 wantLength = exchangeWantAssets[requestId]
                            .length;

                        wantAssets[j] = new address[](wantLength);
                        wantAssetsParams[j] = new bytes[](wantLength);
                        for (k = 0; k < wantLength; k++) {
                            wantAssets[j][k] = exchangeWantAssets[requestId][k];
                            wantAssetsParams[j][k] = exchangeWantAssetsParams[
                                requestId
                            ][k];
                        }
                    }

                    j += 1;
                }
            }
        }
    }

    /**
     * @notice return all exchange requests
     * @param _requester requester address
     * @param _offset index offset
     * @param _size return size
     */
    function myExchanges(
        address _requester,
        uint256 _offset,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory requestIds,
            address[][] memory haveAssets,
            bytes[][] memory haveAssetsParams,
            address[][] memory wantAssets,
            bytes[][] memory wantAssetsParams
        )
    {
        EnumerableSet.UintSet storage _myRequestIds = myRequestIds[_requester];
        uint256 length = Math.min(_myRequestIds.length() - _offset, _size);

        if (length > 0) {
            // initialize the length
            {
                requestIds = new uint256[](length);
                haveAssets = new address[][](length);
                haveAssetsParams = new bytes[][](length);
                wantAssets = new address[][](length);
                wantAssetsParams = new bytes[][](length);
            }

            uint256 i;
            uint256 j;

            for (i = 0; i < length; i++) {
                uint256 requestId = _myRequestIds.at(i + _offset);

                // requestIds
                requestIds[i] = requestId;

                // haveAssets & haveAssetsParams
                {
                    uint256 haveLength = exchangeHaveAssets[requestId].length;

                    haveAssets[i] = new address[](haveLength);
                    haveAssetsParams[i] = new bytes[](haveLength);
                    for (j = 0; j < haveLength; j++) {
                        haveAssets[i][j] = exchangeHaveAssets[requestId][j];
                        haveAssetsParams[i][j] = exchangeHaveAssetsParams[
                            requestId
                        ][j];
                    }
                }

                // wantAssets & wantAssetsParams
                {
                    uint256 wantLength = exchangeWantAssets[requestId].length;

                    wantAssets[i] = new address[](wantLength);
                    wantAssetsParams[i] = new bytes[](wantLength);
                    for (j = 0; j < wantLength; j++) {
                        wantAssets[i][j] = exchangeWantAssets[requestId][j];
                        wantAssetsParams[i][j] = exchangeWantAssetsParams[
                            requestId
                        ][j];
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IEscrowExchange {
    function createExchangeRequest(
        address[] memory _haveAssets,
        bytes[] memory _haveAssetsParams,
        address[] memory _wantAssets,
        bytes[] memory _wantAssetsParams,
        address[] memory _whitelistedExecutors
    ) external;

    function executeExchangeRequest(uint256 _requestId) external;

    function cancelExchangeRequest(uint256 _requestId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

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