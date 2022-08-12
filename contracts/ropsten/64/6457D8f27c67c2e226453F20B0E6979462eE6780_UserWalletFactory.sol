// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Address.sol';
import './UserWallet.sol';
import './MinimalProxyFactory.sol';

contract UserWalletFactory is MinimalProxyFactory {
    using Address for address;
    address public immutable userWalletPrototype;

    constructor() {
        userWalletPrototype = address(new UserWallet());
    }

    function getBytecodeHash() public view returns(bytes32) {
        return keccak256(_deployBytecode(userWalletPrototype));
    }

    function getUserWallet(address _user) public view returns(IUserWallet) {
        address _predictedAddress = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            bytes32(uint(_user)),
            keccak256(_deployBytecode(userWalletPrototype))
        ))));
        if (_predictedAddress.isContract()) {
            return IUserWallet(_predictedAddress);
        }
        return IUserWallet(0);
    }

    function deployUserWallet(address _w2w, address _referrer) external payable {
        deployUserWalletFor(_w2w, msg.sender, _referrer);
    }

    function deployUserWalletFor(address _w2w, address _owner, address _referrer) public payable {
        UserWallet _userWallet = UserWallet(
            _deploy(userWalletPrototype, bytes32(uint(_owner)))
        );
        _userWallet.init{value: msg.value}(_w2w, _owner, _referrer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Constants.sol';
import './IUserWallet.sol';
import './ParamsLib.sol';
import './SafeERC20.sol';

contract UserWallet is IUserWallet, Constants {
    using SafeERC20 for IERC20;
    using ParamsLib for *;

    mapping (bytes32 => bytes32) public override params;

    event ParamUpdated(bytes32 _key, bytes32 _value);

    modifier onlyW2wOrOwner () {
        require(msg.sender == params[W2W].toAddress() || msg.sender == owner(), 'Only W2W or owner');
        _;
    }

    modifier onlyOwner () {
        require(msg.sender == owner(), 'Only owner');
        _;
    }

    function init(address _w2w, address _owner, address _referrer) external payable {
        require(owner() == address(0), 'Already initialized');
        params[OWNER] = _owner.toBytes32();
        params[W2W] = _w2w.toBytes32();
        if (_referrer != address(0)) {
            params[REFERRER] = _referrer.toBytes32();
        }
    }

    function demandETH(address payable _recepient, uint _amount) external override onlyW2wOrOwner() {
        _recepient.transfer(_amount);
    }

    function demandERC20(IERC20 _token, address _recepient, uint _amount) external override onlyW2wOrOwner() {
        uint _thisBalance = _token.balanceOf(address(this));
        if (_thisBalance < _amount) {
            _token.safeTransferFrom(owner(), address(this), (_amount - _thisBalance), '');
        }
        _token.safeTransfer(_recepient, _amount, '');
    }

    function demandAll(IERC20[] calldata _tokens, address payable _recepient) external override onlyW2wOrOwner() {
        for (uint _i = 0; _i < _tokens.length; _i++) {
            IERC20 _token = _tokens[_i];
            if (_token == ETH) {
                _recepient.transfer(address(this).balance);
            } else {
                _token.safeTransfer(_recepient, _token.balanceOf(address(this)), '');
            }
        }
    }

    function demand(address payable _target, uint _value, bytes memory _data) 
    external override onlyW2wOrOwner() returns(bool, bytes memory) {
        return _target.call{value: _value}(_data);
    }

    function owner() public view override returns(address payable) {
        return params[OWNER].toAddress();
    }

    function changeParam(bytes32 _key, bytes32 _value) public onlyOwner() {
        require(_key != REFERRER, 'Cannot update referrer');
        params[_key] = _value;
        emit ParamUpdated(_key, _value);
    }
    
    function changeOwner(address _newOwner) public {
        changeParam(OWNER, _newOwner.toBytes32());
    }

    receive() payable external {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @notice Based on @openzeppelin SafeERC20.
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value, bytes memory errPrefix) internal {
        require(_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value)),
            string(abi.encodePacked(errPrefix, 'ERC20 transfer failed')));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value, bytes memory errPrefix) internal {
        require(_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value)),
            string(abi.encodePacked(errPrefix, 'ERC20 transferFrom failed')));
    }

    function safeApprove(IERC20 token, address spender, uint256 value, bytes memory errPrefix) internal {
        if (_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value))) {
            return;
        }
        require(_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0))
            && _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value)),
            string(abi.encodePacked(errPrefix, 'ERC20 approve failed')));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private returns(bool) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        if (!success) {
            return false;
        }

        if (returndata.length >= 32) { // Return data is optional
            return abi.decode(returndata, (bool));
        }

        // In a wierd case when return data is 1-31 bytes long - return false.
        return returndata.length == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

library ParamsLib {
    function toBytes32(address _self) internal pure returns(bytes32) {
        return bytes32(uint(_self));
    }

    function toAddress(bytes32 _self) internal pure returns(address payable) {
        return address(uint(_self));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

contract MinimalProxyFactory {
    function _deployBytecode(address _prototype) internal pure returns(bytes memory) {
        return abi.encodePacked(
            hex'602d600081600a8239f3363d3d373d3d3d363d73',
            _prototype,
            hex'5af43d82803e903d91602b57fd5bf3'
        );
    }

    function _deploy(address _prototype, bytes32 _salt) internal returns(address payable _result) {
        bytes memory _bytecode = _deployBytecode(_prototype);
        assembly {
            _result := create2(0, add(_bytecode, 32), mload(_bytecode), _salt)
        }
        return _result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IUserWallet {
    function params(bytes32 _key) external view returns(bytes32);
    function owner() external view returns(address payable);
    function demandETH(address payable _recepient, uint _amount) external;
    function demandERC20(IERC20 _token, address _recepient, uint _amount) external;
    function demandAll(IERC20[] calldata _tokens, address payable _recepient) external;
    function demand(address payable _target, uint _value, bytes memory _data) 
        external returns(bool, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract Constants {
    IERC20 constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    bytes32 constant W2W = 'W2W';
    bytes32 constant OWNER = 'OWNER';
    bytes32 constant REFERRER = 'REFERRER';
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.7.0;

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