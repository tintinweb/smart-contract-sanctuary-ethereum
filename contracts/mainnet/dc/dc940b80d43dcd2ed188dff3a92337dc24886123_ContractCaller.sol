/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

interface IERC223TokenCloned {
    // initialize cloned token just for ERC223TokenCloned
    function initialize(address newOwner, string calldata name, string calldata symbol, uint8 decimals) external;
    function mint(address user, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external returns(bool);
    function burn(uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract ContractCaller {
    using TransferHelper for address;
    address constant MAX_NATIVE_COINS = address(31); // addresses from address(1) to MAX_NATIVE_COINS are considered as native coins 

    event RescuedTokens(address token, address to, uint256 balance);

    modifier onlyOwner() {
        require(msg.sender == address(0x6A56D0f7498C9f2AEb9Bb6892Ade5b2E0A50379F), "Only owner"); // owner multisig
        _;
    }

    modifier onlyBridge() {
        require(msg.sender == address(0x9a1fc8C0369D49f3040bF49c1490E7006657ea56), "Only bridge"); // Bridge contract address
        _;
    }

    function tokenReceived(address _from, uint _value, bytes calldata _data) external {
        require(_from == address(0x9a1fc8C0369D49f3040bF49c1490E7006657ea56), "Only from bridge"); // Bridge contract address
    }
    
    function rescueTokens(address token, address to) external onlyOwner {
        uint256 balance;
        if (token == address(0)) {
            balance = address(this).balance;
            to.safeTransferETH(balance);
        } else {
            balance = IERC223TokenCloned(token).balanceOf(address(this));
            token.safeTransfer(to, balance);
        }
        emit RescuedTokens(token, to, balance);
    }

    function callContract(address user, address token, uint256 value, address toContract, bytes memory data) external payable onlyBridge {
        if (token <= MAX_NATIVE_COINS) {
            value = msg.value;
            uint balanceBefore = address(this).balance - value; // balance before
            (bool success,) = toContract.call{value: value}(data);
            if (success) value = address(this).balance - balanceBefore; // check, if we have some rest of token
            if (value != 0) user.safeTransferETH(value);  // send coin to user
        } else {
            token.safeApprove(toContract, value);
            (bool success,) = toContract.call{value: 0}(data);
            if (success) value = IERC223TokenCloned(token).allowance(address(this), toContract); // unused amount (the rest) = allowance
            if (value != 0) {   // if not all value used reset approvement
                token.safeApprove(toContract, 0);
                token.safeTransfer(user, value);   // send to user rest of tokens
            }                
        }
    }
}