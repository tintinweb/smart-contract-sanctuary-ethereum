/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address _address) external view returns (uint256);
}

contract MarketFaucet {

    event TransactionBytes(bytes transactionBytes);

    uint256 constant public waitTime = 24 hours;

    mapping(address => uint256) nextAccessTime;

    function allowedToWithdraw(address _address) public view returns (bool) {
        return block.timestamp >= nextAccessTime[_address];
    }

    // pass in array of token addresses with a receiving address
    function sendMultiTokens(address[] memory _tokenAddresses, address _address) public {
        require(allowedToWithdraw(_address), "Wait 24 hours");
        require(_address != address(0));
        
        nextAccessTime[_address] = block.timestamp + waitTime;

        for(uint i=0; i<_tokenAddresses.length; i++) {
            uint amount = ERC20(_tokenAddresses[i]).balanceOf(address(this)) / 100;
            if (amount > 0) {
                _safeTransfer(_tokenAddresses[i], _address, amount);
            }
        }
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(ERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    receive() external payable {
    }
}