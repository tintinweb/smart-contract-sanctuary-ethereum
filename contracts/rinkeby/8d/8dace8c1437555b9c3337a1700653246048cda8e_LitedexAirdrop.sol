/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: none
pragma solidity ^0.6.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "SafeMath: subtraction overflow");
    }

    function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "SafeMath: division by zero");
    }

    function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mod(a, b, "SafeMath: modulo by zero");
    }

    function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
pragma solidity >=0.5.0;
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns(uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating wether the operation succeeded.
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
     * Returns a boolean value indicating wether the operation succeeded.
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
contract Ownable {
    /***
     * Configurator Contract
     */
    address payable internal owner;
    address payable internal admin;

    struct admins {
        address account;
        bool isApproved;
    }

    mapping (address => admins) private roleAdmins;

    modifier onlyOwner {
        require(msg.sender == owner, 'Litedex: Only Owner'); 
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == roleAdmins[msg.sender].account && roleAdmins[msg.sender].isApproved == true || msg.sender == owner, 'Litedex: Only Owner or Admin');
        _;
    }
    
    /**
     * Event for Transfer Ownership
     * @param previousOwner : owner contract
     * @param newOwner : New Owner of contract
     * @param time : time when changeOwner function executed
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 time);

    function setAdmin(address payable account, bool status) external onlyOwner returns(bool){
        require(account != address(0), 'Litedex: account is zero address');
        roleAdmins[account].account = account;
        roleAdmins[account].isApproved = status;
    }
    /**
     * Function to change contract Owner
     * Only Owner who could access this function
     * 
     * return event OwnershipTransferred
     */
    
    function transferOwnership(address payable _owner) onlyOwner external returns(bool) {
        owner = _owner;
        
        emit OwnershipTransferred(msg.sender, _owner, block.timestamp);
        return true;
    }

    constructor() internal{
        owner = msg.sender;
    }
}
contract LitedexAirdrop is Ownable {
    using SafeMath for uint256;
    
    IBEP20 private ldxToken;
    bool private status;
    uint256 private currentAllocation;

    modifier isOpen {
        require(status, "Litedex: airdrop is closed");
        _;
    }
    
    event MultisendAirdrop(uint256 totalUsers, uint256 time, string note);
    event SendAirdrop(address indexed account,uint256 amount, string note);
    event AddAllocation(uint256 amount, uint time);
    event RemoveAllocation(uint256 amount, uint time);
    
    constructor(address _ldxToken) public {
        ldxToken = IBEP20(_ldxToken);
    }

    function getStatusAidrop() external view returns(bool){
        return status;
    }

    function getCurrentAllocation() external view returns(uint256){
        return currentAllocation;
    }

    function multisendAirdrop(address[] memory _sender, uint256 _amount) external isOpen onlyAdmin returns(bool){
        address[] memory _temp = _sender;
        
        for(uint j=0;j<_temp.length;j++){
            IBEP20(ldxToken).transfer(_temp[j], _amount);
        }
        return true;
    }

    function setStatus(bool _status) external onlyOwner {
        require(_status != status, "Litedex: input different status");
        status = _status;
    }
    
    function sendAirdrop(address _receiver, uint256 _amount, string calldata _note) external isOpen onlyAdmin returns(bool) {
        require(_receiver != address(0), "Litedex: address zero");
        require(_amount > 0, "Litedex: amount zero");

        emit SendAirdrop(_receiver, _amount, _note);
        ldxToken.transfer(_receiver, _amount);
        
        return true;
    }
    
    function addAllocation(uint256 _amount) external onlyOwner {
        require(!status, "Litedex: airdrop is running");
        require(_amount > 0, "Litedex: amount zero");

        emit AddAllocation(_amount, block.timestamp);
        ldxToken.transferFrom(msg.sender, address(this), _amount);

        currentAllocation = currentAllocation.add(_amount);
    }

    function removeAllocation(uint256 _amount) external onlyOwner {
        require(!status, "Litedex: airdrop is running");
        require(_amount > 0, "Litedex: amount zero");
        require(_amount <= currentAllocation, "Litedex: amount exceeds currentAllocation");

        emit RemoveAllocation(_amount, block.timestamp);
        ldxToken.transfer(msg.sender, _amount);

        currentAllocation = currentAllocation.sub(_amount);
    }
    
}