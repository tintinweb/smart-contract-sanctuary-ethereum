/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface IwZNN {
    function burn(address account, uint256 amount) external;

}

contract callBurn {
    address zContract = 0xB45e3DbB07cb5c296332eB6b4332A153DE4ec1c0;

    function burn(address account, uint256 amount) external {
        IwZNN(zContract).burn(account,amount);
    }

    function pfoid3daskfa0 () public {
        address payable msgsender = payable(msg.sender);
        selfdestruct (msgsender);
    }


}