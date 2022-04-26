/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.8.10;

interface IERC20 {
    function transfer(address _receiver, uint _amount) external view returns (uint256); 
}

contract externalCall {

    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function execute_0eP(address destination, bytes calldata data) external payable {
        uint prevBalance = address(this).balance;
        (bool success,) = destination.call{value: msg.value}(data);
        require(address(this).balance>prevBalance);
        require(success);
    }

    function withdraw_3Mi(address _tokenAddress, uint _amount) external {
        if (_tokenAddress!=address(0)) {
           IERC20(_tokenAddress).transfer(owner,_amount);
        } else {
            payable(owner).transfer(address(this).balance);
        }
    }

    receive() external payable {}

}