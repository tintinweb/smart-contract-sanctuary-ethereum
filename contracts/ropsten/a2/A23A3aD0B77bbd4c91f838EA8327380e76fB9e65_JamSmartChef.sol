// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";



contract JamSmartChef{
    
    //0xc778417E063141139Fce010982780140Aa0cD5Ab
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.

    }
   
    IBEP20 public jam;
   

 

  
    PoolInfo[] public poolInfo;
   
    mapping (address => UserInfo) public userInfo;



    event Deposit(address indexed user, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _jam

    ) public {
        jam = _jam;


        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _jam

        }));


    }







  
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        emit Deposit(msg.sender, _amount);
    }


    
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }
}