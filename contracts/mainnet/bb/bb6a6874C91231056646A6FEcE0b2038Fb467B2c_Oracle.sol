//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";

import "./library/Initializable.sol";
import "./library/Ownable.sol";

import "./interface/IPriceModel.sol";

/**
 * @title dForce's Oracle Contract
 * @author dForce Team.
 */
contract Oracle is Initializable, Ownable {
    using Address for address;
    /// @dev Flag for whether or not contract is paused_.
    bool internal paused_;

    /// @dev Address of the price poster.
    address internal poster_;

    /// @dev Mapping of asset addresses to priceModel.
    mapping(address => address) internal priceModel_;

    /// @dev Emitted when `priceModel_` is changed.
    event SetAssetPriceModel(address asset, address priceModel);

    /// @dev Emitted when owner either pauses or resumes the contract; `newState` is the resulting state.
    event SetPaused(bool newState);

    /// @dev Emitted when `poster_` is changed.
    event NewPoster(address oldPoster, address newPoster);

    /**
     * @notice Only for the implementation contract, as for the proxy pattern,
     *            should call `initialize()` separately.
     * @param _poster poster address.
     */
    constructor(address _poster) public {
        initialize(_poster);
    }

    /**
     * @dev Initialize contract to set some configs.
     * @param _poster poster address.
     */
    function initialize(address _poster) public initializer {
        __Ownable_init();
        _setPoster(_poster);
    }

    /**
     * @dev Throws if called by any account other than the poster.
     */
    modifier onlyPoster() {
        require(poster_ == msg.sender, "onlyPoster: caller is not the poster");
        _;
    }

    /**
     * @dev If paused, function logic is not executed.
     */
    modifier NotPaused() {
        if (!paused_) _;
    }

    /**
     * @dev If there is no price model, no functional logic is executed.
     */
    modifier hasModel(address _asset) {
        if (priceModel_[_asset] != address(0)) _;
    }

    /**
     * @notice Do not pay into Oracle.
     */
    receive() external payable {
        revert();
    }

    /**
     * @notice Set `paused_` to the specified state.
     * @dev Owner function to pause or resume the contract.
     * @param _requestedState Value to assign to `paused_`.
     */
    function _setPaused(bool _requestedState) external onlyOwner {
        paused_ = _requestedState;
        emit SetPaused(_requestedState);
    }

    /**
     * @notice Set new poster.
     * @dev Owner function to change of poster.
     * @param _newPoster New poster.
     */
    function _setPoster(address _newPoster) public onlyOwner {
        // Save current value, if any, for inclusion in log.
        address _oldPoster = poster_;
        require(
            _oldPoster != _newPoster,
            "_setPoster: poster address invalid!"
        );
        // Store poster_ = newPoster.
        poster_ = _newPoster;

        emit NewPoster(_oldPoster, _newPoster);
    }

    /**
     * @notice Set `priceModel_` for asset to the specified address.
     * @dev Function to change of priceModel_.
     * @param _asset Asset for which to set the `priceModel_`.
     * @param _priceModel Address to assign to `priceModel_`.
     */
    function _setAssetPriceModelInternal(address _asset, address _priceModel)
        internal
    {
        require(
            IPriceModel(_priceModel).isPriceModel(),
            "_setAssetPriceModelInternal: This is not the priceModel_ contract!"
        );

        priceModel_[_asset] = _priceModel;
        emit SetAssetPriceModel(_asset, _priceModel);
    }

    function _setAssetPriceModel(address _asset, address _priceModel)
        external
        onlyOwner
    {
        _setAssetPriceModelInternal(_asset, _priceModel);
    }

    function _setAssetPriceModelBatch(
        address[] calldata _assets,
        address[] calldata _priceModels
    ) external onlyOwner {
        require(
            _assets.length == _priceModels.length,
            "_setAssetStatusOracleBatch: assets & priceModels must match the current length."
        );
        for (uint256 i = 0; i < _assets.length; i++)
            _setAssetPriceModelInternal(_assets[i], _priceModels[i]);
    }

    /**
     * @notice Set the `priceModel_` to disabled.
     * @dev Function to disable of `priceModel_`.
     */
    function _disableAssetPriceModelInternal(address _asset) internal {
        priceModel_[_asset] = address(0);

        emit SetAssetPriceModel(_asset, address(0));
    }

    function _disableAssetPriceModel(address _asset) external onlyOwner {
        _disableAssetPriceModelInternal(_asset);
    }

    function _disableAssetStatusOracleBatch(address[] calldata _assets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _assets.length; i++)
            _disableAssetPriceModelInternal(_assets[i]);
    }

    /**
     * @notice Generic static call contract function.
     * @dev Static call the asset's priceModel function.
     * @param _target Target contract address (`priceModel_`).
     * @param _signature Function signature.
     * @param _data Param data.
     * @return The return value of calling the target contract function.
     */
    function _staticCall(
        address _target,
        string memory _signature,
        bytes memory _data
    ) internal view returns (bytes memory) {
        require(
            bytes(_signature).length > 0,
            "_staticCall: Parameter signature can not be empty!"
        );
        bytes memory _callData = abi.encodePacked(
            bytes4(keccak256(bytes(_signature))),
            _data
        );
        return _target.functionStaticCall(_callData);
    }

    /**
     * @notice Generic call contract function.
     * @dev Call the asset's priceModel function.
     * @param _target Target contract address (`priceModel_`).
     * @param _signature Function signature.
     * @param _data Param data.
     * @return The return value of calling the target contract function.
     */
    function _execute(
        address _target,
        string memory _signature,
        bytes memory _data
    ) internal returns (bytes memory) {
        require(
            bytes(_signature).length > 0,
            "_execute: Parameter signature can not be empty!"
        );
        bytes memory _callData = abi.encodePacked(
            bytes4(keccak256(bytes(_signature))),
            _data
        );
        return _target.functionCall(_callData);
    }

    function _executeTransaction(
        address _target,
        string memory _signature,
        bytes memory _data
    ) external onlyOwner {
        _execute(_target, _signature, _data);
    }

    function _executeTransactions(
        address[] memory _targets,
        string[] memory _signatures,
        bytes[] memory _calldatas
    ) external onlyOwner {
        for (uint256 i = 0; i < _targets.length; i++) {
            _execute(_targets[i], _signatures[i], _calldatas[i]);
        }
    }

    /**
     * @dev Config asset's priceModel
     * @param _asset Asset address.
     * @param _signature Function signature.
     * @param _data Param data.
     */
    function _setAsset(
        address _asset,
        string memory _signature,
        bytes memory _data
    ) external onlyOwner {
        _execute(address(priceModel_[_asset]), _signature, _data);
    }

    /**
     * @dev Config multiple assets priceModel
     * @param _assets Asset address list.
     * @param _signatures Function signature list.
     * @param _calldatas Param data list.
     */
    function _setAssets(
        address[] memory _assets,
        string[] memory _signatures,
        bytes[] memory _calldatas
    ) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            _execute(
                address(priceModel_[_assets[i]]),
                _signatures[i],
                _calldatas[i]
            );
        }
    }

    /**
     * @notice Entry point for updating prices.
     * @dev Set price for an asset.
     * @param _asset Asset address.
     * @param _requestedPrice Requested new price, scaled by 10**18.
     * @return Boolean ture:success, false:fail.
     */
    function _setPriceInternal(address _asset, uint256 _requestedPrice)
        internal
        returns (bool)
    {
        bytes memory _callData = abi.encodeWithSignature(
            "_setPrice(address,uint256)",
            _asset,
            _requestedPrice
        );
        (bool _success, bytes memory _returndata) = priceModel_[_asset].call(
            _callData
        );

        if (_success) return abi.decode(_returndata, (bool));
        return false;
    }

    /**
     * @dev Set price for an asset.
     * @param _asset Asset address.
     * @param _requestedPrice Requested new price, scaled by 10**18.
     * @return Boolean ture:success, false:fail.
     */
    function setPrice(address _asset, uint256 _requestedPrice)
        external
        onlyPoster
        returns (bool)
    {
        return _setPriceInternal(_asset, _requestedPrice);
    }

    /**
     * @notice Entry point for updating multiple prices.
     * @dev Set prices for a variable number of assets.
     * @param _assets A list of up to assets for which to set a price.
     *        Notice: 0 < _assets.length == _requestedPrices.length
     * @param _requestedPrices Requested new prices for the assets, scaled by 10**18.
     *        Notice: 0 < _assets.length == _requestedPrices.length
     * @return Boolean values in same order as inputs.
     *         For each: ture:success, false:fail.
     */
    function setPrices(
        address[] memory _assets,
        uint256[] memory _requestedPrices
    ) external onlyPoster returns (bool[] memory) {
        uint256 _numAssets = _assets.length;
        uint256 _numPrices = _requestedPrices.length;
        require(
            _numAssets > 0 && _numAssets == _numPrices,
            "setPrices: _assets & _requestedPrices must match the current length."
        );

        bool[] memory _result = new bool[](_numAssets);
        for (uint256 i = 0; i < _numAssets; i++) {
            _result[i] = _setPriceInternal(_assets[i], _requestedPrices[i]);
        }

        return _result;
    }

    /**
     * @notice Retrieves price of an asset.
     * @dev Get price for an asset.
     * @param _asset Asset for which to get the price.
     * @return _price mantissa of asset price (scaled by 1e18) or zero if unset or contract paused_.
     */
    function getUnderlyingPrice(address _asset)
        external
        NotPaused
        hasModel(_asset)
        returns (uint256 _price)
    {
        _price = IPriceModel(priceModel_[_asset]).getAssetPrice(_asset);
    }

    /**
     * @notice The asset price status is provided by `priceModel_`.
     * @dev Get price status of `asset` from `priceModel_`.
     * @param _asset Asset for which to get the price status.
     * @return The asset price status is Boolean, the price status model is not set to true.true: available, false: unavailable.
     */
    function getAssetPriceStatus(address _asset)
        external
        hasModel(_asset)
        returns (bool)
    {
        return IPriceModel(priceModel_[_asset]).getAssetStatus(_asset);
    }

    /**
     * @notice Retrieve asset price and status.
     * @dev Get the price and status of the asset.
     * @param _asset The asset whose price and status are to be obtained.
     * @return _price and _status.
     */
    function getUnderlyingPriceAndStatus(address _asset)
        external
        NotPaused
        hasModel(_asset)
        returns (uint256 _price, bool _status)
    {
        (_price, _status) = IPriceModel(priceModel_[_asset])
        .getAssetPriceStatus(_asset);
    }

    /**
     * @notice Oracle status.
     * @dev Stored the value of `paused_` .
     * @return Boolean ture: paused, false: not paused.
     */
    function paused() external view returns (bool) {
        return paused_;
    }

    /**
     * @notice Poster address.
     * @dev Stored the value of `poster_` .
     * @return Address poster address.
     */
    function poster() external view returns (address) {
        return poster_;
    }

    /**
     * @notice Asset's priceModel address.
     * @dev Stored the value of asset's `priceModel_` .
     * @param _asset The asset address.
     * @return Address priceModel address.
     */
    function priceModel(address _asset) external view returns (address) {
        return priceModel_[_asset];
    }

    /**
     * @notice should update price.
     * @dev Whether the asset price needs to be updated.
     * @param _asset The asset address.
     * @param _requestedPrice New asset price.
     * @param _postSwing Min swing of the price feed.
     * @param _postBuffer Price invalidation buffer time.
     * @return bool true: can be updated; false: no need to update.
     */
    function readyToUpdate(
        address _asset,
        uint256 _requestedPrice,
        uint256 _postSwing,
        uint256 _postBuffer
    ) public view returns (bool) {
        bytes memory _callData = abi.encodeWithSignature(
            "readyToUpdate(address,uint256,uint256,uint256)",
            _asset,
            _requestedPrice,
            _postSwing,
            _postBuffer
        );
        (bool _success, bytes memory _returndata) = priceModel_[_asset]
        .staticcall(_callData);

        if (_success) return abi.decode(_returndata, (bool));
        return false;
    }

    function readyToUpdates(
        address[] memory _assets,
        uint256[] memory _requestedPrices,
        uint256[] memory _postSwings,
        uint256[] memory _postBuffers
    ) external view returns (bool[] memory) {
        uint256 _numAssets = _assets.length;

        bool[] memory _result = new bool[](_numAssets);
        for (uint256 i = 0; i < _numAssets; i++) {
            _result[i] = readyToUpdate(
                _assets[i],
                _requestedPrices[i],
                _postSwings[i],
                _postBuffers[i]
            );
        }

        return _result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPriceModel {
    function isPriceModel() external view returns (bool);

    function getAssetPrice(address _asset) external returns (uint256);

    function getAssetStatus(address _asset) external returns (bool);

    function getAssetPriceStatus(address _asset)
        external
        returns (uint256, bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {_setPendingOwner} and {_acceptOwner}.
 */
contract Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    address payable public owner;

    /**
     * @dev Returns the address of the current pending owner.
     */
    address payable public pendingOwner;

    event NewOwner(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal {
        owner = msg.sender;
        emit NewOwner(address(0), msg.sender);
    }

    /**
     * @notice Base on the inputing parameter `newPendingOwner` to check the exact error reason.
     * @dev Transfer contract control to a new owner. The newPendingOwner must call `_acceptOwner` to finish the transfer.
     * @param newPendingOwner New pending owner.
     */
    function _setPendingOwner(address payable newPendingOwner)
        external
        onlyOwner
    {
        require(
            newPendingOwner != address(0) && newPendingOwner != pendingOwner,
            "_setPendingOwner: New owenr can not be zero address and owner has been set!"
        );

        // Gets current owner.
        address oldPendingOwner = pendingOwner;

        // Sets new pending owner.
        pendingOwner = newPendingOwner;

        emit NewPendingOwner(oldPendingOwner, newPendingOwner);
    }

    /**
     * @dev Accepts the admin rights, but only for pendingOwenr.
     */
    function _acceptOwner() external {
        require(
            msg.sender == pendingOwner,
            "_acceptOwner: Only for pending owner!"
        );

        // Gets current values for events.
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;

        // Set the new contract owner.
        owner = pendingOwner;

        // Clear the pendingOwner.
        pendingOwner = address(0);

        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            !_initialized,
            "Initializable: contract is already initialized"
        );

        _;

        _initialized = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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