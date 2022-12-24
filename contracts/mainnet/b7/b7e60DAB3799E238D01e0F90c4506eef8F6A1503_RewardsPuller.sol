// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
}

contract RewardsPuller {
    address public target = 0x527e80008D212E2891C737Ba8a2768a7337D7Fd2;
    address public governance = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;

    function pull(address _token, address _source) external {
        uint amount = IERC20(_token).balanceOf(_source);
        if(amount > 0){
            IERC20(_token).transferFrom(_source, target, amount);
        }
    }

    function sweep(address _token) external {
        uint amount = IERC20(_token).balanceOf(address(this));
        if(amount > 0){
            IERC20(_token).transfer(target, amount);
        }
    }

    function setTarget(address _target) external {
        require(msg.sender == governance);
        target = _target;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance);
        governance = _governance;
    }
}