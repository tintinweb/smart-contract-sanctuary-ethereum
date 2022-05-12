/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// File: contracts/interfaces/IBEP20.sol



pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
// File: contracts/BalancePredictor.sol


pragma solidity ^0.8.13;


contract BalancePredictorMF {
    
    uint256 private totalSupplyMF = 10000000000 * 10 ** 9;
    uint256 private totalSupplyGV = 5850 * 10 ** 18;
    uint256 private constant allocatedMoonForce = 2000000000 * 10 ** 9;

    address public constant MoonForceMainnet = 0xEcE3D017A62b8723F3648a9Fa7cD92f603E88a0E;
    address public constant GravityMainnet = 0x8B9386354C6244232e44E03932f2484b37fB94E2;
    address public MoonForce = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    address public Gravity = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;


    function predictMFBalance() public view returns (uint256) {
        uint256 weightedBalanceMF = (IBEP20(address(MoonForce)).balanceOf(address(msg.sender)) / totalSupplyMF);
        uint256 weightedBalanceGV = (IBEP20(address(Gravity)).balanceOf(address(msg.sender)) / totalSupplyGV);
        uint256 predictedBalanceMF;

        if (weightedBalanceMF == 0 && weightedBalanceGV == 0) {
            return 0;
        } else {
            uint256 adjustedBalanceMF = weightedBalanceMF * allocatedMoonForce;
            uint256 adjustedBalanceGV = weightedBalanceGV * allocatedMoonForce;
            predictedBalanceMF = adjustedBalanceGV + adjustedBalanceMF;
            return predictedBalanceMF;
        }   
    }

    // if holder's balance is staked, user enters thier token balance manually
    function predictBalanceIfStaked(uint256 _amountMF, uint256 _amountGV) public view returns (uint256) {
        uint256 weightedBalanceMF = ((_amountMF * 10 ** 9) / totalSupplyMF);
        uint256 weightedBalanceGV = ((_amountGV * 10 ** 18) / totalSupplyGV);
        uint256 predictedBalanceMF;

        if (weightedBalanceMF == 0 && weightedBalanceGV == 0) {
            return 0;
        } else {
            uint256 adjustedBalanceMF = weightedBalanceMF * allocatedMoonForce;
            uint256 adjustedBalanceGV = weightedBalanceGV * allocatedMoonForce;
            predictedBalanceMF = adjustedBalanceGV + adjustedBalanceMF;
            return predictedBalanceMF;
        }  
    }






}