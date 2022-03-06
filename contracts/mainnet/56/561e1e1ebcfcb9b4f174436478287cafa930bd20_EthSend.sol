/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

pragma solidity 0.8.12;

contract EthSend {
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function sendEth(address recipient) public payable {
        uint256 length;
        assembly {
            length := extcodesize(recipient)
        }
        if (length == 0) {
            payable(recipient).call{ value: msg.value }("");
        } else {
            uint256 amount = msg.value;
            weth.deposit{ value: msg.value }();
            weth.transfer(recipient, amount);
        }
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}