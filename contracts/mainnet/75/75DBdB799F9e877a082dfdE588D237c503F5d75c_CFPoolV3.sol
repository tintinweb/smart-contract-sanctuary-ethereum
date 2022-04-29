/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.10;



// Part: ICurveDepositGate

// external interfaces
contract ICurveDepositGate {
    function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) public;
    function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount) public;
}

// Part: ICurvePool

// legacy interface for this
contract ICurvePool {
    function deposit(uint256 _amount) public;
    function withdraw(uint256 _amount) public;
    function earnReward(address[] memory yieldtokens) public;

    function get_virtual_price() public view returns(uint256);
    function get_lp_token_balance() public view returns(uint256);
    function get_lp_token_addr() public view returns(address);

    function setController(address, address) public;
}

// Part: ICurveVirtualPrive

contract ICurveVirtualPrive{
    function get_virtual_price() public view returns(uint256);
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: IFeiRewardsDistributor

contract IFeiRewardsDistributor {
    function claimRewards(address holder, address[] memory cTokens) public;
}

// Part: Ownable

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// Part: SafeMath

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSubR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b <= a, s);
        c = a - b;
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
    function safeDivR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b > 0, s);
        c = a / b;
    }
}

// Part: IFeiDelegator

contract IFeiDelegator is IERC20 {
    function balanceOfUnderlying(address owner) public returns(uint256);
    function mint(uint256 mintAmount) public;
    function redeemUnderlying(uint256 redeemAmount) public;
}

// File: CFPool.sol

contract CFPoolV3 is Ownable, ICurvePool{
    using SafeMath for uint256;

    address public controller;
    address public vault;

    IERC20 public target_token;
    ICurveDepositGate public curve_deposit_gate;
    IERC20 public curve_lp_token;
    IFeiDelegator public fei_delegator;
    IFeiRewardsDistributor public fei_rewards_distributor;
    
    uint256 public underlying_curve_lp_balance;   // curve lp

    constructor(address _fei_delegator, address _fei_rewards_distributor) public {
        // pool spcificly build for Fei.money
        target_token = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        curve_deposit_gate = ICurveDepositGate(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
        curve_lp_token = IERC20(0x06cb22615BA53E60D67Bf6C341a0fD5E718E1655);
        fei_delegator = IFeiDelegator(_fei_delegator); // passing as param for test purpose
        fei_rewards_distributor = IFeiRewardsDistributor(_fei_rewards_distributor);
    }

    modifier onlyAdmin() {
        require(msg.sender == controller || msg.sender == vault);
        _;
    }
    
    /**
     * on start, target token already at dealer
     * deposit to curve'pool and then fei's pool
     */
    function deposit(uint256 amount) public onlyAdmin {
        // deposit to curve's f3 pool
        target_token.approve(address(curve_deposit_gate), 0);
        target_token.approve(address(curve_deposit_gate), amount);
        curve_deposit_gate.add_liquidity(address(curve_lp_token), [0, 0, amount, 0], 0);
        
        // deposit to fei's pool
        uint256 curve_lp_amount = curve_lp_token.balanceOf(address(this));
        curve_lp_token.approve(address(fei_delegator), 0);
        curve_lp_token.approve(address(fei_delegator), curve_lp_amount);
        fei_delegator.mint(curve_lp_amount);

        underlying_curve_lp_balance = underlying_curve_lp_balance+curve_lp_amount;
    }

    /**
     * withdraw from fei's pool
     * withdraw from curve's pool
     * send back to vault
     * @param amount in fei's lp token
     */
    function withdraw(uint256 amount) public onlyAdmin {
        // withdraw from fei's pool
        // require(amount < fei_delegator.balanceOf(address(this)))
        fei_delegator.redeemUnderlying(amount);
        // withdraw from curve's pool
        uint256 curve_lp_amount = curve_lp_token.balanceOf(address(this));
        curve_lp_token.approve(address(curve_deposit_gate), 0);
        curve_lp_token.approve(address(curve_deposit_gate), curve_lp_amount);
        curve_deposit_gate.remove_liquidity_one_coin(address(curve_lp_token), curve_lp_amount, 2, 0);

        target_token.transfer(vault, target_token.balanceOf(address(this)));
        underlying_curve_lp_balance = underlying_curve_lp_balance-curve_lp_amount;
    }

    /**
     * mint rewards
     * transfer to controller
     */
    function earnReward(address[] memory yield_tokens) public onlyAdmin {
        address[] memory ctokens = new address[](1);
        ctokens[0] = address(fei_delegator);
        fei_rewards_distributor.claimRewards(address(this), ctokens);

        for (uint i = 0; i < yield_tokens.length; i++) {
            uint256 balance = IERC20(yield_tokens[i]).balanceOf(address(this));
            IERC20(yield_tokens[i]).transfer(controller, balance);
        }
    }

    
    function get_lp_token_balance() public view returns(uint256) {
        return underlying_curve_lp_balance;
    }
    function get_lp_token_addr() public view returns(address) {
        return address(fei_delegator);
    }
    function get_virtual_price() public view returns(uint256) {
        uint256 vir = ICurveVirtualPrive(address(curve_lp_token)).get_virtual_price();
        //uint256 b = fei_delegator.balanceOf(address(this));
        //return underlying_curve_lp_balance.safeMul(vir);
        return vir;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    function setController(address _controller, address _vault) public onlyOwner{
        controller = _controller;
        vault = _vault;
    }

    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }
}