// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IRewardHook.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFxsClaim{
    function claimFees(address _distroContract, address _token) external;
}

//hook that claims vefxs fees
contract FXSRewardHook is IRewardHook{

    address public constant booster = address(0xA2cF21b157b2f203e37b616b619f438B5aa86Ee5);
    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant distro = address(0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872);
    address public constant stash = address(0x4f3AD55D7b884CDC48ADD1e2451A13af17887F26);
    address public constant prevhook = address(0x0f29b765be2DE395cb6b10D9Ead46975057B51eD);

    //address to call for other reward pulls
    address public rewardHook;
    address public owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);

    constructor() public {}

    function setRewardHook(address _hook) external{
        require(msg.sender == owner, "!auth");

        rewardHook = _hook;
    }

    function onRewardClaim() override external{
        require(msg.sender == prevhook,"!auth");

        IFxsClaim(booster).claimFees(distro,fxs);

        if(rewardHook != address(0)){
            try IRewardHook(rewardHook).onRewardClaim(){
            }catch{}
        }

        //check if any fxs made its way here by other means
        uint256 bal = IERC20(fxs).balanceOf(address(this));
        if(bal > 0){
            IERC20(fxs).transfer(stash,bal);
        }
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount, address _withdrawTo) external{
        require(msg.sender == owner, "!auth");
        require(_tokenAddress != fxs, "protected");
        IERC20(_tokenAddress).transfer(_withdrawTo, _tokenAmount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardHook {
    function onRewardClaim() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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