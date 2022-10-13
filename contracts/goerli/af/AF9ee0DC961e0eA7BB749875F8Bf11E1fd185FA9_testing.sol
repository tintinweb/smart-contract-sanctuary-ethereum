/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// File: Celo Hackathon/IERC20.sol



pragma solidity ^0.8.4;

interface IERC20 {

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


}

// File: Celo Hackathon/test.sol



pragma solidity ^0.8.4;


contract testing {




    function depositIntoDAO (uint amount, address contractAddr) public {
        IERC20(contractAddr).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw (uint amount, address contractAddr) public {
         IERC20(contractAddr).transfer( address(this), amount);
    }


}