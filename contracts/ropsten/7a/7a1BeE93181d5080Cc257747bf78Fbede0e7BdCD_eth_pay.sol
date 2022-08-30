/**
 *Submitted for verification at Etherscan.io on 2022-08-29
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
    uint256 public IDcounter = 1;

    USDT public TokenContract;
    address public fundWallet;

    struct trade {
        uint256 id;
        uint256 fees;
        string coin;
        uint amount;
        address buyer;
        address seller;
        uint state;   // 0=>not started,  1=>deposit,  2=>dispute,  3=>withdrawed
    } 

    mapping(uint256 => trade) public trades;
    mapping(uint256 => bool) public id_exist;

    constructor(string memory _name , string memory _symbol, address _fundWallet, USDT _TokenContract) {
        name   = _name;
        symbol = _symbol;
        fundWallet = _fundWallet;
        TokenContract = _TokenContract;
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

    // ETH and USDT
    function changeFundAddress(address _address) public onlyOwner{
        fundWallet = _address;
    }

    // ETH
    function startTrade (address _seller) public payable {
        require(msg.value > 0, "payable amount > 0");
        require(_seller != address(0), "invalid seller address");
        require(!id_exist[IDcounter], "trade id already exist");

        trades[ IDcounter ].id     = IDcounter;
        trades[ IDcounter ].fees   = fee;
        trades[ IDcounter ].coin   = "ETH";
        trades[ IDcounter ].amount = msg.value;
        trades[ IDcounter ].buyer  = msg.sender;
        trades[ IDcounter ].seller = _seller;
        trades[ IDcounter ].state  = 1;
        id_exist[ IDcounter ] = true;
        IDcounter++;

        uint256 __owner  = (msg.value * fee) / 1000;
        payable(fundWallet).transfer(__owner);

        emit StartTrade(msg.sender, _seller, msg.value, "ETH");
    }

    // ETH and USDT
    function StartDispute (uint256 _tradeId) public {
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer == msg.sender || trades[_tradeId].seller == msg.sender, "invalid caller");
        require(trades[_tradeId].buyer != address(0) && trades[_tradeId].seller != address(0), "invalid partner");
        require(trades[_tradeId].state == 1, "error in start dispute");
        
        trades[ _tradeId ].state  = 2;
        emit DisputeStart(msg.sender, _tradeId);
    }

    // USDT
    function startTradeUSDT (address _seller, uint _amount) public payable {
        require( USDT(TokenContract).balanceOf(msg.sender) > 0,  "you don't have enough balance");
        require( USDT(TokenContract).allowance(msg.sender, address(this)) >= _amount,  "approve or increase allowance");
        require(_seller != address(0), "invalid seller address");
        require(!id_exist[IDcounter], "trade id already exist");

        trades[ IDcounter ].id     = IDcounter;
        trades[ IDcounter ].fees   = feeUSDT;
        trades[ IDcounter ].coin   = "USDT";
        trades[ IDcounter ].amount = _amount;
        trades[ IDcounter ].buyer  = msg.sender;
        trades[ IDcounter ].seller = _seller;
        trades[ IDcounter ].state  = 1;
        id_exist[IDcounter] = true;
        IDcounter++;

        uint256 __owner  = (_amount * feeUSDT) / 1000;
        uint256 __seller = (_amount * (1000 - feeUSDT)) / 1000;
        USDT(TokenContract).transferFrom(msg.sender, fundWallet, __owner);
        USDT(TokenContract).transferFrom(msg.sender, address(this), __seller);

    }

    // ETH
    function handleDispute (address _buyer, address _seller, address winner, uint256 _tradeId) public onlyOwner() {
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer == _buyer, "invalid buyer");
        require(trades[_tradeId].seller == _seller, "invalid seller");
        require(trades[_tradeId].state == 2, "trade is not set as dispute");
        require(trades[_tradeId].seller == winner || trades[_tradeId].buyer == winner, "invalid winner");
        require(keccak256(abi.encodePacked(trades[_tradeId].coin)) == keccak256(abi.encodePacked("ETH")),  "invalid request");
        uint256 __amount = (trades[_tradeId].amount * (1000 - trades[_tradeId].fees)) / 1000;
        payable(winner).transfer(__amount);
        
        trades[ _tradeId ].state  = 3;
        emit DisputeResolve(msg.sender, winner, _tradeId);
    }
    
    // USDT
    function handleDisputeUSDT (address _buyer, address _seller, address winner, uint256 _tradeId) public onlyOwner() {
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer == _buyer, "invalid buyer");
        require(trades[_tradeId].seller == _seller, "invalid seller");
        require(keccak256(abi.encodePacked(trades[_tradeId].coin)) == keccak256(abi.encodePacked("USDT")),  "invalid request");
        require(trades[_tradeId].state == 2, "unable to update trade state");
        require(trades[_tradeId].seller == winner || trades[_tradeId].buyer == winner, "invalid winner");

        payUSDTtoWinner(_tradeId, winner);
    }
    function payUSDTtoWinner(uint _tradeId,address winner) internal {
        uint256 __amount = (trades[_tradeId].amount * (1000 - trades[_tradeId].fees)) / 1000;
        USDT(TokenContract).transfer(winner, __amount);
        trades[ _tradeId ].state  = 3;
        emit DisputeResolve(address(this), winner, _tradeId);
    }
    
    // ETH
    function withdraw (uint256 _tradeId) public payable {
        require(msg.sender == owner(), "Invalid caller");
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer  != address(0), "invalid buyer address");
        require(trades[_tradeId].seller != address(0), "invalid seller address");
        require(trades[_tradeId].state == 1, "unable to update trade state");
        require(keccak256(abi.encodePacked(trades[_tradeId].coin)) == keccak256(abi.encodePacked("ETH")),  "invalid request");
        
        uint256 __seller = (trades[_tradeId].amount * (1000 - trades[_tradeId].fees)) / 1000;        
        payable(trades[_tradeId].seller).transfer(__seller);
        
        trades[ _tradeId ].state = 3;
        emit CompleteTrade(trades[_tradeId].buyer, trades[_tradeId].seller, __seller, trades[_tradeId].coin);
    }
    
    // USDT
    function withdrawUSDT (uint256 _tradeId) public payable {
        require(msg.sender == owner(), "Invalid caller");
        require(id_exist[_tradeId], "trade id is not exist");
        require(trades[_tradeId].buyer != address(0), "invalid buyer address");
        require(trades[_tradeId].seller != address(0), "invalid seller address");
        require(trades[_tradeId].state == 1, "you can not withdraw now");
        require(keccak256(abi.encodePacked(trades[_tradeId].coin)) == keccak256(abi.encodePacked("USDT")),  "invalid request");

        payUSDTtoSeller(_tradeId);
    }
    function payUSDTtoSeller(uint _tradeId) internal {
        uint256 __seller = (trades[_tradeId].amount * (1000 - trades[_tradeId].fees)) / 1000;
        USDT(TokenContract).transfer(trades[_tradeId].seller, __seller);
        trades[ _tradeId ].state  = 3;
        emit CompleteTrade(trades[_tradeId].buyer, trades[_tradeId].seller, __seller, trades[_tradeId].coin);
    }



    // EVENTS
    event StartTrade(address indexed buyer, address indexed seller, uint256 value, string coin);
    event CompleteTrade(address indexed buyer, address indexed seller, uint256 value, string coin);
    
    event DisputeStart(address indexed creator, uint256 tradeId);
    event DisputeResolve(address indexed resolver, address indexed winner, uint256 tradeId);


}