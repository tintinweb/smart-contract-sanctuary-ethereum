/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

// May, 11th 2022
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

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

interface USDT {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address from, address to, uint256 amount ) external returns (bool);
}


contract eth_pay is Ownable {

    string public name;
    string public symbol;
    uint public fee = 100;       // 50%
    uint public feeUSDT = 100;  //  50%

    USDT public TokenContract;
    address public fundWallet;

    struct trade {
        string id;
        string coin;
        uint amount;
        address buyer;
        address seller;
        uint state;   // 0 => not started, 1 => deposit, 2 => can withdraw, 3 => withdrawed, 4 => dispute, 5 => dispute done
    } 

    mapping(string => trade) public trades;
    mapping(string => bool) public id_exist;

    constructor(string memory _name , string memory _symbol) {
        name   = _name;
        symbol = _symbol;
    }

    // (fee * 10)  / 1000 => 1%
    // (fee * 100) / 1000 => 10%
    // (fee * 500) / 1000 => 50%
    // ETH
    function updateFee(uint _fee) public onlyOwner{
        require(fee != _fee, "Invalid fee");
        require(_fee > 0, "Invalid fee");
        fee = _fee;
    }

    // USDT
    function updateFeeUSDT(uint _fee) public onlyOwner{
        require(feeUSDT != _fee, "Invalid fee");
        require(_fee > 0, "Invalid fee");
        feeUSDT = _fee;
    }

    // USDT
    function setToken (USDT _TokenContract) public onlyOwner{
        TokenContract = _TokenContract;
    }

    // ETN and USDT
    function changeFundAddress(address _address) public onlyOwner{
        fundWallet = _address;
    }

    // ETH
    function startTrade (address _seller, string memory __id) public payable {
        require(msg.value > 0, "payable amount > 0");
        require(_seller != address(0), "invalid seller address");
        require(!id_exist[__id], "trade id already exist");

        trades[ __id ].id     = __id;
        trades[ __id ].coin   = "ETH";
        trades[ __id ].amount = msg.value;
        trades[ __id ].buyer  = msg.sender;
        trades[ __id ].seller = _seller;
        trades[ __id ].state  = 1;
        id_exist[__id] = true;

    }

    // USDT
    function startTradeUSDT (address _seller, string memory __id, uint _amount) public payable {
        require( USDT(TokenContract).balanceOf(msg.sender) > 0,  "payable amount > 0");
        require(_seller != address(0), "invalid seller address");
        require(!id_exist[__id], "trade id already exist");

        trades[ __id ].id     = __id;
        trades[ __id ].coin   = "USDT";
        trades[ __id ].amount = _amount;
        trades[ __id ].buyer  = msg.sender;
        trades[ __id ].seller = _seller;
        trades[ __id ].state  = 1;
        id_exist[__id] = true;

        USDT(TokenContract).transferFrom(msg.sender, address(this), _amount);

    }

    // ETH and USDT
    function updateState (string memory _tradeId, uint newState) public {
        require(newState == 2 || newState == 4, "invalid state entered");
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer == msg.sender, "invalid buyer");
        require(trades[_tradeId].seller != address(0), "invalid seller");
        require(trades[_tradeId].state == 1 || trades[_tradeId].state == 2, "unable to update trade state");
        
        trades[ _tradeId ].state  = newState;
    }

    // ETH
    function handleDispute (address _buyer, address _seller, address winner, string memory _tradeId) public onlyOwner() {
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer == _buyer, "invalid buyer");
        require(trades[_tradeId].seller == _seller, "invalid seller");
        require(trades[_tradeId].state == 4, "unable to update trade state");
        require(trades[_tradeId].seller == winner || trades[_tradeId].buyer == winner, "invalid winner");
 
        uint256 __owner  = (trades[_tradeId].amount * fee) / 1000;
        uint256 __amount = (trades[_tradeId].amount * (1000 - fee)) / 1000;
        payable(winner).transfer(__amount);
        payable(fundWallet).transfer(__owner);
        
        trades[ _tradeId ].state  = 5;
    }
    
    // USDT
    function handleDisputeUSDT (address _buyer, address _seller, address winner, string memory _tradeId) public onlyOwner() {
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer == _buyer, "invalid buyer");
        require(trades[_tradeId].seller == _seller, "invalid seller");
        require(trades[_tradeId].state == 4, "unable to update trade state");
        require(trades[_tradeId].seller == winner || trades[_tradeId].buyer == winner, "invalid winner");
 
        uint256 __owner  = (trades[_tradeId].amount * feeUSDT) / 1000;
        uint256 __amount = (trades[_tradeId].amount * (1000 - feeUSDT)) / 1000;
        USDT(TokenContract).transfer(winner, __amount);
        USDT(TokenContract).transfer(fundWallet, __owner);
                
        trades[ _tradeId ].state  = 5;
    }
    
    // ETH
    function withdraw (string memory _tradeId) public payable {
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer != address(0), "invalid buyer address");
        require(trades[_tradeId].seller == msg.sender, "invalid seller address");
        require(trades[_tradeId].state == 2, "you can not withdraw now");

        uint256 __owner  = (trades[_tradeId].amount * fee) / 1000;
        uint256 __seller = (trades[_tradeId].amount * (1000 - fee)) / 1000;
        
        payable(trades[_tradeId].seller).transfer(__seller);
        payable(fundWallet).transfer(__owner);
        
        trades[ _tradeId ].state  = 3;
    }
    
    // USDT
    function withdrawUSDT (string memory _tradeId) public payable {
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer != address(0), "invalid buyer address");
        require(trades[_tradeId].seller == msg.sender, "invalid seller address");
        require(trades[_tradeId].state == 2, "you can not withdraw now");

        uint256 __owner  = (trades[_tradeId].amount * feeUSDT) / 1000;
        uint256 __seller = (trades[_tradeId].amount * (1000 - feeUSDT)) / 1000;
        USDT(TokenContract).transfer(trades[_tradeId].seller, __seller);
        USDT(TokenContract).transfer(fundWallet, __owner);
        
        trades[ _tradeId ].state  = 3;
    }

}