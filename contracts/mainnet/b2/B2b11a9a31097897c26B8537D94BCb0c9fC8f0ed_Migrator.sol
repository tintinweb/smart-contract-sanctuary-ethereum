/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function apPROve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event ApPROval(address indexed owner, address indexed spender, uint256 value);
}
interface StakeV2{
    function getPending1(address staker) external view returns(uint256 _pendingReward);
    function getPending2(address staker) external view returns(uint256 _pendingReward);
    function getPending3(address staker) external view returns(uint256 _pendingReward);
    function isStakeholder(address _address) external view returns(bool);
    function userStakedFEG(address user) external view returns(uint256 StakedFEG);
}

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

interface StakeV1{
     function yourStakedFEG(address staker) external view returns(uint256 stakedFEG);
}

interface ProPair{
    function userBalanceInternal(address _addr) external view returns(uint256, uint256);
}

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}
contract ReEntrancyGuard2 {
    mapping(address=>uint256) internal lastBlock;

    modifier lock(){
        require(lastBlock[msg.sender] < block.number,"No re-entrancy V2");
        lastBlock[msg.sender] = block.number;
        _;

    }
}

                                                                                                                    
contract Migrator is ReEntrancyGuard,ReEntrancyGuard2{
    address public constant V_2         = 0x4a9D6b95459eb9532B7E4d82Ca214a3b20fa2358;
    address public constant V_1         = 0x5bCF1f407c0fc922074283B4e11DaaF539f6644D;
    address public constant FEG         = 0x389999216860AB8E0175387A0c90E5c52522C945;
    address public constant PRO         = 0xf2bda964ec2D2fcB1610c886eD4831bf58f64948;
    address public constant NEW_PAIR    = 0xBA993532E7b66029077b794383eB0Cb75CcDD72D; 
    address public constant dev         = 0x765Cf9485CD66960608a0B8Dd79d39FCBC847904; 
    address public constant DEAD        = 0x000000000000000000000000000000000000dEaD; 

    uint256  public constant  RATIO = 1_000;

    mapping(address=>bool) public v1Claimed;
    mapping(address=>uint256) public amtClaimed;
    


    function balanceEligable(address holder) public view returns(uint256){
            return IERC20(FEG).balanceOf(holder)*RATIO;
    }




    function lPEligable(address holder) public view  returns(uint256){
        return ((IERC20(PRO).balanceOf(holder)*117/100)/10**9)*RATIO;
    }

    function stakingV2Eligable(address holder) public view returns(uint256){
        return StakeV2(V_2).userStakedFEG(holder) * RATIO;
    }

    function stakingV1Eligable(address holder) public view returns(uint256){
        if (v1Claimed[holder]) return 0;
        return StakeV1(V_1).yourStakedFEG(holder) * RATIO;
    }

    function totalEligable(address holder) external view returns(uint256){
        return  lPEligable(holder) + balanceEligable(holder) +  stakingV2Eligable(holder) + stakingV1Eligable(holder);
    }

    

    function saveLostTokens(address toSave) external { //added function to save any lost tokens
        require(FEG != toSave,"Can't extract FEG");
        require(msg.sender == dev, "You do not have permission");
        uint256 toSend = IERC20(toSave).balanceOf(address(this));
        require(IERC20(toSave).transfer(dev,toSend),"Extraction Transfer failed");
    }
  
    function singleStepMigrationBalance() external noReentrant lock{
        require(msg.sender == tx.origin, "no contract allowed");
        address user = msg.sender;
        uint256 toSend =balanceEligable(user);
        TransferHelper.safeTransferFrom(FEG,user,address(this),IERC20(FEG).balanceOf(user));
        require(IERC20(NEW_PAIR).transfer(user,toSend),"New token Transfer failed");
        amtClaimed[user] += toSend;
    }

    function singleStepMigrationLP() external noReentrant lock{
        require(msg.sender == tx.origin, "no contract allowed");
        address user = msg.sender;
        uint256 toSend = ((IERC20(PRO).balanceOf(user)*117/100)/10**9)*RATIO;
        TransferHelper.safeTransferFrom(PRO,user,address(this),IERC20(PRO).balanceOf(user));
        require(IERC20(NEW_PAIR).transfer(user,toSend),"New token Transfer failed");
        amtClaimed[user] += toSend;
    }

    function singleStepMigrationStakingV1() external noReentrant lock{
        require(msg.sender == tx.origin, "no contract allowed");
        address user = msg.sender;
        require(!v1Claimed[user],"You already claimed V_1");
        uint256 toSend = StakeV1(V_1).yourStakedFEG(user) * RATIO;
        v1Claimed[user] = true;
        require(IERC20(NEW_PAIR).transfer(user,toSend),"New token Transfer failed");
        amtClaimed[user] += toSend;
    }

    function singleStepMigrationStakingV2() external noReentrant lock{
        require(msg.sender == tx.origin, "no contract allowed");
        address user = msg.sender;
        require(StakeV2(V_2).isStakeholder(user),"You are not a stakeholder");
        require( StakeV2(V_2).getPending1(user) == 0 && StakeV2(V_2).getPending2(user) == 0 && StakeV2(V_2).getPending3(user) == 0, "Please claim your Staking rewards" );
        uint256 toSend = StakeV2(V_2).userStakedFEG(user) * RATIO;
        TransferHelper.safeTransferFrom(V_2,user,address(this),IERC20(V_2).balanceOf(user));
        require(IERC20(NEW_PAIR).transfer(user,toSend),"New token Transfer failed");
        amtClaimed[user] += toSend;
    }

    function singleStepMigrationStakingV2WithoutRewardsClaim() external noReentrant lock{
        require(msg.sender == tx.origin, "no contract allowed");
        address user = msg.sender;
        uint256 toSend = StakeV2(V_2).userStakedFEG(user) * RATIO;
        TransferHelper.safeTransferFrom(V_2,user,address(this),IERC20(V_2).balanceOf(user));
        require(IERC20(NEW_PAIR).transfer(user,toSend),"New token Transfer failed");
        amtClaimed[user] += toSend;
    }


    function migrate() external noReentrant lock{
        require(msg.sender == tx.origin, "no contract allowed");
        address user = msg.sender;
        uint256 toSend = 0;
        //balance
        if(IERC20(FEG).balanceOf(user) > 0){
            require( IERC20(FEG).allowance(user,address(this)) >= IERC20(FEG).balanceOf(user),"Please apPROve your FEG balance");
            toSend += balanceEligable(user);
            TransferHelper.safeTransferFrom(FEG,user,address(this),IERC20(FEG).balanceOf(user));
        }
        //Staking V_2
        if(IERC20(V_2).balanceOf(user) > 0){
            //V_2 logic
            toSend += StakeV2(V_2).userStakedFEG(user) * RATIO;
            TransferHelper.safeTransferFrom(V_2,user,address(this),IERC20(V_2).balanceOf(user));
        }
        //Staking V_1
        if(!v1Claimed[user]){
            toSend += StakeV1(V_1).yourStakedFEG(user) * RATIO;
            v1Claimed[user] = true;
        }
        //liquidity in PROpair
        if(IERC20(PRO).balanceOf(user)>0){
            toSend += ((IERC20(PRO).balanceOf(user)*117/100)/10**9)*RATIO;
            TransferHelper.safeTransferFrom(PRO,user,address(this),IERC20(PRO).balanceOf(user));
        }
        //checks if the person get's anything
        require(toSend > 0,"Nothing to migrate");
        require(IERC20(NEW_PAIR).transfer(user,toSend),"New token Transfer failed");
    }

function migrateView(address user) external view returns(uint toSend){
        //balance
        if(IERC20(FEG).balanceOf(user) > 0){
            toSend += balanceEligable(user);
        }
        //Staking V_2
        if(IERC20(V_2).balanceOf(address(this)) > 0){
            //V_2 logic
            toSend += StakeV2(V_2).userStakedFEG(user) * RATIO;
        }
        //Staking V_1
        if(!v1Claimed[user]){
            toSend += StakeV1(V_1).yourStakedFEG(user) * RATIO;
        }
        //liquidity in PROpair
        if(IERC20(PRO).balanceOf(user)>0){
            toSend += ((IERC20(PRO).balanceOf(user)*117/100)/10**9)*RATIO;
        }

        //checks if the person get's anything
    }


}