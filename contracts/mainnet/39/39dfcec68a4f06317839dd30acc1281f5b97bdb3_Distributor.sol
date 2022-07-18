//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);
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
interface IKeysStaking {
    function deposit(uint256 amount) external;
}
/**
 *
 * KEYS Distributor
 * Will Allocate Funding To Different Sources
 *
 */
contract Distributor {
        
    // Farming Manager
    address public farm;
    address public stake;
    address public multisig;
    // KEYS
    address public constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;
    
    // allocation to farm + stake + multisig
    uint256 public farmFee;
    uint256 public stakeFee;
    uint256 public multisigFee;
    
    // ownership
    address public _master;
    modifier onlyMaster(){require(_master == msg.sender, 'Sender Not Master'); _;}
    // distribution approval
    mapping ( address => bool ) public canCallDistribute;
    
    constructor() {
    
        _master = 0x9006a76c1f12ca173ffc48648352DD5da402e356;
        multisig = 0xdfcFCEa5e7AC10914478D5289ea44B227fEBD997;
        farm = 0x810487135d29f35f06f1075b48D5978F1791d743;
        stake = 0x73940d8E53b3cF00D92e3EBFfa33b4d54626306D;
    
        stakeFee = 32;
        farmFee = 48;
        multisigFee = 20;
        canCallDistribute[multisig] = true;
        canCallDistribute[0x9006a76c1f12ca173ffc48648352DD5da402e356] = true;
        canCallDistribute[0x8d9Be7185Aa2ca944d89779F908a1E4867BE538b] = true;
        canCallDistribute[0x9271d72d60910f64a845caCbadfceF4F4FbF05B8] = true;
    }
    
    event SetFarm(address farm);
    event SetStaker(address staker);
    event SetMultisig(address multisig);
    event SetFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent);
    event Withdrawal(uint256 amount);
    event OwnershipTransferred(address newOwner);
    
    // MASTER 
    function setCanCallDistribute(address user, bool canCall) external onlyMaster {
        canCallDistribute[user] = canCall;
    }
    
    function setFarm(address _farm) external onlyMaster {
        farm = _farm;
        emit SetFarm(_farm);
    }
    
    function setStake(address _stake) external onlyMaster {
        stake = _stake;
        emit SetStaker(_stake);
    }
    
    function setMultisig(address _multisig) external onlyMaster {
        multisig = _multisig;
        emit SetMultisig(_multisig);
    }
    
    function setFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent) external onlyMaster {
        farmFee = farmPercentage;
        stakeFee = stakePercent;
        multisigFee = multisigPercent;
        emit SetFundPercents(farmPercentage, stakePercent, multisigPercent);
    }
    
    function manualWithdraw(address token) external onlyMaster {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0);
        IERC20(token).transfer(_master, bal);
        emit Withdrawal(bal);
    }
    
    function ETHWithdrawal() external onlyMaster returns (bool s){
        uint256 bal = address(this).balance;
        require(bal > 0);
        (s,) = payable(_master).call{value: bal}("");
        emit Withdrawal(bal);
    }
    
    function transferMaster(address newMaster) external onlyMaster {
        _master = newMaster;
        emit OwnershipTransferred(newMaster);
    }
    
    
    // ONLY APPROVED
    
    function distribute() external {
        require(
            canCallDistribute[msg.sender],
            'Not Allowed'
        );
        _distributeYield();
    }
    // PRIVATE
    
    function _distributeYield() private {
        
        uint256 keysBal = IERC20(KEYS).balanceOf(address(this));
        
        uint256 farmBal = (keysBal * farmFee) / 100;
        uint256 sigBal = (keysBal * multisigFee) / 100;
        uint256 stakeBal = (keysBal * stakeFee) / 100;
        if (farmBal > 0 && farm != address(0)) {
            IERC20(KEYS).approve(farm, farmBal);
            IKeysStaking(farm).deposit(farmBal);
        }
        
        if (sigBal > 0 && multisig != address(0)) {
            IERC20(KEYS).transfer(multisig, sigBal);
        }
        if (stakeBal > 0 && stake != address(0)) {
            IERC20(KEYS).transfer(stake, IERC20(KEYS).balanceOf(address(this)));
        }
    }
    
    receive() external payable {
        (bool s,) = payable(KEYS).call{value: msg.value}("");
        require(s, 'Failure on Token Purchase');
        if (canCallDistribute[msg.sender]) {
            _distributeYield();
        }
    }
    
}