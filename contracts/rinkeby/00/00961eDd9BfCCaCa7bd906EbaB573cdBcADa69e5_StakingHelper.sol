// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IERC20.sol';
import './interfaces/IStaking.sol';


contract StakingHelper {

    address public immutable staking;
    address public immutable OHM;

    constructor ( address _staking, address _OHM ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _OHM != address(0) );
        OHM = _OHM;
    }

    function stake( uint _amount ) external {
        IERC20( OHM ).transferFrom( msg.sender, address(this), _amount );
        IERC20( OHM ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, msg.sender );
        IStaking( staking ).claim( msg.sender );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
    function unstake( uint _amount, address _recipient ) external returns ( bool );
    function index() external view returns ( uint );
}