/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) external isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

abstract contract ERC20 {
    function decimals() external virtual view returns (uint8 decimals_);
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
    function transfer(address _to, uint256 _value) external virtual returns (bool success);
    function allowance(address _owner, address _spender) external virtual view returns (uint256 remaining);
    function balanceOf(address _owner) external virtual view returns (uint256 balance);
}

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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * 
 * Stakes Almond v.3
 *
 * Stakes is an interest gain contract for ERC-20 tokens
 * 
 * asset is the ERC20 token to deposit
 * asset2 is the ERC20 token to get interest
 * interest_rate: percentage rate of token1
 * interest_rate2: percentage rate of token2
 * maturity is the time in seconds after which is safe to end the stake
 * penalization for ending a stake before maturity time
 * lower_amount is the minimum amount for creating a stake
 * 
 */
contract StakesAlmond is Owner, ReentrancyGuard {

    using SafeERC20 for ERC20;

    // token to deposit
    ERC20 public asset;

    // token to pay interest
    ERC20 public asset2;

    // stakes history
    struct Record {
        uint256 from;
        uint256 amount;
        uint256 gain;
        uint256 gain2;
        uint256 penalization;
        uint256 to;
        bool ended;
    }

    // contract parameters
    uint16 public interest_rate;
    uint16 public interest_rate2;
    uint256 public maturity;
    uint8 public penalization;
    uint256 public lower_amount;

    // conversion ratio for token1 and token2
    // 1:10 ratio will be: 
    // ratio1 = 1 
    // ratio2 = 10
    uint256 public ratio1;
    uint256 public ratio2;

    mapping(address => Record[]) public ledger;

    event StakeStart(address indexed user, uint256 value, uint256 index);
    event StakeEnd(address indexed user, uint256 value, uint256 penalty, uint256 interest, uint256 index);
    
    event ChangeRatio1(uint256 newRatio);
    event ChangeRatio2(uint256 newRatio);

    constructor(
        ERC20 _erc20, ERC20 _erc20_2, address _owner, uint16 _rate, uint16 _rate2, uint256 _maturity, 
        uint8 _penalization, uint256 _lower, uint256 _ratio1, uint256 _ratio2) Owner(_owner) {
        require(_penalization<=100, "Penalty has to be an integer between 0 and 100");
        asset = _erc20;
        asset2 = _erc20_2;
        ratio1 = _ratio1;
        ratio2 = _ratio2;
        interest_rate = _rate;
        interest_rate2 = _rate2;
        maturity = _maturity;
        penalization = _penalization;
        lower_amount = _lower;
    }
    
    function start(uint256 _value) external nonReentrant {
        require(_value >= lower_amount, "Invalid value");
        asset.safeTransferFrom(msg.sender, address(this), _value);
        ledger[msg.sender].push(Record(block.timestamp, _value, 0, 0, 0, 0, false));
        emit StakeStart(msg.sender, _value, ledger[msg.sender].length-1);
    }

    function end(uint256 i) external nonReentrant {

        require(i < ledger[msg.sender].length, "Invalid index");
        require(!ledger[msg.sender][i].ended, "Invalid stake");
        
        // penalization
        if(block.timestamp - ledger[msg.sender][i].from < maturity) {

            uint256 _penalization = ledger[msg.sender][i].amount * penalization / 100;
            ledger[msg.sender][i].penalization = _penalization;
            ledger[msg.sender][i].to = block.timestamp;
            ledger[msg.sender][i].ended = true;
            emit StakeEnd(msg.sender, ledger[msg.sender][i].amount, _penalization, 0, i);

            asset.safeTransfer(msg.sender, ledger[msg.sender][i].amount - _penalization);
            asset.safeTransfer(getOwner(), _penalization);

        // interest gained
        } else {
            
            // interest is calculated in asset2
            uint256 _interest = get_gains(msg.sender, i);

            // check that the owner can pay interest before trying to pay, token 1
            if (asset.allowance(getOwner(), address(this)) < _interest || asset.balanceOf(getOwner()) < _interest) {
                _interest = 0;
            }

            // interest is calculated in asset2
            uint256 _interest2 = get_gains2(msg.sender, i);

            // check that the owner can pay interest before trying to pay, token 1
            if (asset2.allowance(getOwner(), address(this)) < _interest2 || asset2.balanceOf(getOwner()) < _interest2) {
                _interest2 = 0;
            }

            // the original asset is returned to the investor
            ledger[msg.sender][i].gain = _interest;
            ledger[msg.sender][i].gain2 = _interest2;
            ledger[msg.sender][i].to = block.timestamp;
            ledger[msg.sender][i].ended = true;
            emit StakeEnd(msg.sender, ledger[msg.sender][i].amount, 0, _interest, i);

            asset.safeTransfer(msg.sender, ledger[msg.sender][i].amount);

            if (_interest > 0) {
                asset.safeTransferFrom(getOwner(), msg.sender, _interest);
            }

            if (_interest2 > 0) {
                asset2.safeTransferFrom(getOwner(), msg.sender, _interest2);
            }

        }
    }

    function set(ERC20 _erc20, ERC20 _erc20_2, uint256 _lower, uint256 _maturity, uint16 _rate, uint16 _rate2, uint8 _penalization, uint256 _ratio1, uint256 _ratio2) external isOwner {
        require(_penalization<=100, "Invalid value");
        asset = _erc20;
        asset2 = _erc20_2;
        ratio1 = _ratio1;
        ratio2 = _ratio2;
        lower_amount = _lower;
        maturity = _maturity;
        interest_rate = _rate;
        interest_rate2 = _rate2;
        penalization = _penalization;

        emit ChangeRatio1(ratio1);
        emit ChangeRatio2(ratio2);

    }

    // calculate interest of the token 1 to the current date time
    function get_gains(address _address, uint256 _rec_number) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp - ledger[_address][_rec_number].from;
        uint256 _year_seconds = 365*24*60*60;
        return _record_seconds * 
            ledger[_address][_rec_number].amount * interest_rate / 100
        / _year_seconds;
    }

    // calculate interest to the current date time
    function get_gains2(address _address, uint256 _rec_number) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp - ledger[_address][_rec_number].from;
        uint256 _year_seconds = 365*24*60*60;
        
        /**
         *
         * Oririginal code:
         * 
         *   // now we calculate the value of the transforming the staked asset (asset) into the asset2
         *   // first we calculate the ratio
         *   uint256 value_in_asset2 = ledger[_address][_rec_number].amount * ratio2 / ratio1;
         *   // now we transform into decimals of the asset2
         *   value_in_asset2 = value_in_asset2 * 10**asset2.decimals() / 10**asset.decimals();
         *   uint256 interest = _record_seconds * value_in_asset2 * interest_rate2 / 100 / _year_seconds;
         *   // now lets calculate the interest rate based on the converted value in asset 2
         *
         * Simplified into:
         * 
         */

        return (_record_seconds * ledger[_address][_rec_number].amount * ratio2 * 10**asset2.decimals() * interest_rate2) / 
               (ratio1 * 10**asset.decimals() * 100 * _year_seconds);

    }

    function ledger_length(address _address) external view 
        returns (uint256) {
        return ledger[_address].length;
    }

}