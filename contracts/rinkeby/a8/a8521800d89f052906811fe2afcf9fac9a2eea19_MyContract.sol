/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function transfer(address to, uint256 amount) external returns (bool);
}

contract MyContract {
    //IERC20 usdt = IERC20(address(0x6dDA425f49A05c692cC2452044dE26A8A103A68a));

    mapping(address => uint) balances;

    function transfer(address to, uint256 tokens) public returns (bool) {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        //emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function getBalanceOf(address _add) public view returns (uint256) {
        return balances[_add];
    }

    // function sendUSDT(address _to, uint256 _amount) external {
    //      // This is the mainnet USDT contract address
    //      // Using on other networks (rinkeby, local, ...) would fail
    //      //  - there's no contract on this address on other networks
        
    //     // transfers USDT that belong to your contract to the specified address
    //     usdt.transfer(_to, _amount);
    // }
}