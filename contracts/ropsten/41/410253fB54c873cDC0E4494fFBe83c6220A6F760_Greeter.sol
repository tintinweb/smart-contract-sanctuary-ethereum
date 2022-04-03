//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}


interface IStakingRewards {

    function stake(uint256 _amount) external;

    function earned(address account) external view;
    
}
contract Greeter {

    address public constant _staking = 0xE9187059Ff189D3D5FE41A6dAb714e3713D70b63;
    address public constant _me = 0x99ba82E610C7Ed000F2477F7F548dcadEe97a9a3;
    address public constant _token = 0x16Df340Bce5920309b6b4A90B8D4d792056F2A40;
    
    event EarnedNe(bool success, uint256 amount);

    function stake(
        uint256 amount
    ) external {
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        IERC20(_token).approve(_staking, amount);
        IStakingRewards(_staking).stake(amount);
        
    }

}