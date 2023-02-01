// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract EarnBox {
    mapping(address => uint256) public userDrvsStaked;
    mapping(address => uint256) public userWithdrawableEth;
    mapping(address => Deposit) public userDeposits;
    uint256 public drvs_pool_balance;
    address public DRVS_VAULT;
    IERC20 public DRVS;
    address public owner;
    address[] public stakers;
    uint256 public global_eth;

    struct Deposit {
        address user;
        uint256 drvs_amt;
    }

    event ProfitInjection(
        uint256 timestamp, 
        uint256 protocolProfit, 
        uint256 ethInjected, 
        uint number_of_stakers, 
        uint256 pool_drvs_amount
    );

    constructor(address _drvs_address, address _drvs_vault_address) {
        owner = msg.sender;
        drvs_pool_balance = 0;
        DRVS_VAULT = _drvs_vault_address;
        DRVS = IERC20(_drvs_address);
    }

    function deposit(uint256 amount) public {
        require(
            amount <= DRVS.balanceOf(msg.sender),
            "You do not own enough DRVS to stake that amount."
        );
        require(
            DRVS.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance to stake DRVS into this contract."
        );
        DRVS.transferFrom(msg.sender, address(this), amount);
        if (userDeposits[msg.sender].drvs_amt == 0) {
            userDeposits[msg.sender] = Deposit(msg.sender, amount);
        } else {
            userDeposits[msg.sender].drvs_amt += amount;
        }
        drvs_pool_balance += amount;
        bool staker_found = false;
        for(uint i=0; i<stakers.length; i++){
            if(stakers[i] == msg.sender){
                staker_found = true;
            }
        }
        if(staker_found == false){
            stakers.push(msg.sender);
        }
    }

    function withdraw(uint256 _drvs_amount) public {
        require(userDeposits[msg.sender].drvs_amt >= _drvs_amount,"DRVS Balance insufficient");
        uint256 percentage_of_users_deposit =  _drvs_amount/
            (userDeposits[msg.sender].drvs_amt / 100);
        uint256 converted_eth_amt = (userWithdrawableEth[msg.sender] * percentage_of_users_deposit) / 100;
        if(userDeposits[msg.sender].drvs_amt-_drvs_amount == 0){
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] != msg.sender) {
                    remove(i);
                    break;
                }
            }
        }
        userDeposits[msg.sender].drvs_amt-=_drvs_amount;
        userWithdrawableEth[msg.sender]-=converted_eth_amt;
        DRVS.transfer(msg.sender,_drvs_amount);
        payable(msg.sender).transfer(converted_eth_amt);
    }

    function inject_profit() external payable{
        require(msg.sender == DRVS_VAULT,"Msg.sender != Vault on earn box...");
        uint256 total_eth_transferred = msg.value;
        for(uint i=0; i<stakers.length; i++){
            uint256 users_share_of_total = (total_eth_transferred * users_share_of_pool(stakers[i])) / 100;
            userWithdrawableEth[stakers[i]] += users_share_of_total;
        }
        emit ProfitInjection(block.timestamp, msg.value*4, msg.value, stakers.length, drvs_pool_balance);
    } 

    function users_share_of_pool(address user) public view returns(uint256){
        uint256 percentage_of_drvs_pool = userDeposits[user].drvs_amt/
            (drvs_pool_balance / 100);
        return(percentage_of_drvs_pool);
    }

   function remove(uint index) internal {
        if (index >= stakers.length) revert();

        for (uint i = index; i<stakers.length-1; i++){
            stakers[i] = stakers[i+1];
        }
        stakers.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}