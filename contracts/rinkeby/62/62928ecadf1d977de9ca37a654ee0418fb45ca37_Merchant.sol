// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
import "./Initializable.sol";

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMerchant {

    struct MerchantInfo {
        address account;
        address payable settleAccount;
        address settleCurrency;
        bool autoSettle;
        address proxy;
        uint256 rate;
        address [] tokens;
    }

    function addMerchant(
        address payable settleAccount,
        address settleCurrency,
        bool autoSettle,
        address proxy,
        uint256 rate,
        address[] memory tokens
    ) external;

    function setMerchantRate(address _merchant, uint256 _rate) external;

    function getMerchantInfo(address _merchant) external view returns(MerchantInfo memory);

    function isMerchant(address _merchant) external view returns(bool);

    function getMerchantTokens(address _merchant) external view returns(address[] memory);

    function getAutoSettle(address _merchant) external view returns(bool);

    function getSettleCurrency(address _merchant) external view returns(address);

    function getSettleAccount(address _merchant) external view returns(address);

    function getGlobalTokens() external view returns(address[] memory);

    function validatorCurrency(address _merchant, address _currency) external view returns (bool);

    function validatorGlobalToken(address _token) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

abstract contract Initializable {

    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
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

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMerchant.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract Merchant is IMerchant, Initializable, OwnableUpgradeable {

    mapping(address => MerchantInfo) public merchantMap;

    address[] public globalTokens;

    event AddMerchant(address merchant, address proxy);

    event SetMerchantRate(address merchant, address proxy, uint256 newRate);

    address public immutable SETTLE_TOKEN;

    receive() payable external {}

    constructor(address _settleToken){
        SETTLE_TOKEN = _settleToken;
    }

    function initialize()public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function addMerchant(
        address payable _settleAccount,
        address _settleCurrency,
        bool _autoSettle,
        address _proxy,
        uint256 _rate,
        address[] memory _tokens
    ) external {

        if(address(0) != _settleCurrency) {
            require(SETTLE_TOKEN == _settleCurrency);
        }

        if(_tokens.length > 0) {
            for(uint i = 0; i < _tokens.length; i++) {
                require(validatorGlobalToken(_tokens[i]));
            }
        }

        merchantMap[msg.sender] = MerchantInfo (msg.sender, _settleAccount, _settleCurrency, _autoSettle, _proxy, _rate, _tokens);

        emit AddMerchant(msg.sender, _proxy);

        emit SetMerchantRate(msg.sender, _proxy, _rate);

    }

    function setMerchantRate(address _merchant, uint256 _rate) external {

        require(msg.sender == merchantMap[_merchant].proxy);

        merchantMap[_merchant].rate = _rate;

        emit SetMerchantRate(_merchant, msg.sender, _rate);

    }

    function getMerchantInfo(address _merchant) external view returns(MerchantInfo memory){
        return merchantMap[_merchant];
    }

    function isMerchant(address _merchant) external view returns(bool) {
        return _isMerchant(_merchant);
    }

    function _isMerchant(address _merchant) public view returns(bool) {
        return merchantMap[_merchant].account != address(0);
    }

    function getMerchantTokens(address _merchant) external view returns(address[] memory) {
        return merchantMap[_merchant].tokens;
    }

    function getAutoSettle(address _merchant) external view returns(bool){
        return merchantMap[_merchant].autoSettle;
    }

    function getSettleCurrency(address _merchant) external view returns(address){
        return merchantMap[_merchant].settleCurrency;
    }

    function getSettleAccount(address _merchant) external view returns(address){
        return merchantMap[_merchant].settleAccount;
    }

    function getGlobalTokens() public view returns(address[] memory){
        return globalTokens;
    }

    function setGlobalTokens(address[] memory _tokens) external onlyOwner{
        globalTokens = _tokens;
    }

    function validatorCurrency(address _merchant, address _currency) public view returns (bool){
        for(uint idx = 0; idx < merchantMap[_merchant].tokens.length; idx ++) {
            if (_currency == merchantMap[_merchant].tokens[idx]) {
                return true;
            }
        }
        return false;
    }

    function validatorGlobalToken(address _token) public view returns (bool){
        for(uint idx = 0; idx < globalTokens.length; idx ++) {
            if (_token == globalTokens[idx]) {
                return true;
            }
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}