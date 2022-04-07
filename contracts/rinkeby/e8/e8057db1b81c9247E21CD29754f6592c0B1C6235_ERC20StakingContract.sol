//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20StakingContract {

    //count all the staking
    uint private stakeId;

    //ERC20 contract
    IERC20 tokenContract;

    //token contract decimal
    uint private decimals=18;

    //staking details
    struct Staking{
        uint stakeId;
        address stakingOwner;
        uint tokenBitsAmount;
        uint timeOfStaking;
    }

    //mapp all the stakings. stakeId => Staking.
    mapping(uint => Staking) public stakings;

    //events for staking
    event staked(address indexed stakingOwner,uint tokenAmount,uint stakeId);
    //events for stake withdraw
    event withdraw(uint withdrawTokenBits,uint remainingTokenBits,uint stakeId);

    constructor(
        IERC20 _tokenContract
    ){
        tokenContract = _tokenContract;
        
    }

    //stake contracts
    function stakeTokens(uint _tokenAmount) public {
        uint tokenBits = tokenBitsAmount(_tokenAmount);

        require(tokenContract.balanceOf(msg.sender)>= tokenBits,"Account have less token");
        require(_tokenAmount >=100,"minimum staking balance is 100 tokens");

        //increase the stake id
        stakeId++;

        Staking memory staking = Staking(
            stakeId,
            msg.sender,
            tokenBits,
            block.timestamp
        );
        //transfer the tokens from staking owner to contract
       tokenContract.transferFrom(staking.stakingOwner,address(this),tokenBits);

        //add the staking to the collections
        stakings[stakeId] = staking;

        //emit the staked events
        emit staked(staking.stakingOwner,_tokenAmount,stakeId);
    }

    //withdraw stake tokens
    function withdrawStake(uint _stakeId,uint _tokenAmount) public{
        require(_stakeId > 0 && _stakeId<=stakeId,"staking Id is not exists");
        uint tokenBits = tokenBitsAmount(_tokenAmount);
        Staking storage staking = stakings[_stakeId];
        require(staking.stakingOwner == msg.sender,"Only staking owner is allowed to withdraw");
        require(staking.tokenBitsAmount >= tokenBits,"Exceeding tokens amount");

        uint updatedTokenBits = staking.tokenBitsAmount - tokenBits ;
       //calculate the ROI
        uint ROItokenBits  = calculateROI(_stakeId,tokenBits);
        //total tokenBits to transfer the stakeOwner
        uint totalTokenBits = tokenBits + ROItokenBits;
        //contract should have enough tokens
        require(tokenContract.balanceOf(address(this)) >= totalTokenBits ,"Contract does not enough Tokens, try after some time");
        //update the staking collection
        staking.tokenBitsAmount = updatedTokenBits;
        //transfer the tokens to the stake owner from this contract address
        tokenContract.transfer(staking.stakingOwner,totalTokenBits);

        //emit the withdraw events
        emit withdraw(tokenBits,staking.tokenBitsAmount,staking.stakeId);

    }

    function calculateROI(uint _stakeId,uint _tokenBits) private view returns(uint){
        Staking memory staking = stakings[_stakeId];
        uint stakingPeriod = block.timestamp-staking.timeOfStaking;
        uint returnPersentage;
        //if staking period is greater than 1 month and less than 6 month ROI is 5%
        if (stakingPeriod >= 4 weeks && stakingPeriod < 24 weeks){
            returnPersentage = 5;
        }
        //if staking period is greater than 6 month and less than 1 year ROI is 10%
        else if(stakingPeriod >= 24 weeks && stakingPeriod < 48 weeks){
            returnPersentage = 10;
        }
        //if staking period is greater than 1 year, ROI is 15%
        else if(stakingPeriod >= 48 weeks) {
            returnPersentage = 15;
        }

        //erc20 decimal is present,considering it into the calculation 
        return (_tokenBits * returnPersentage)/100 ; 

    }

    

    //returns the with tokenBits
    function tokenBitsAmount(uint256 _amount) private view returns (uint256) {
        return _amount * (10**decimals);
    }




}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}