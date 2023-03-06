/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract HushMixer is Ownable {
    mapping(bytes32 => bool) public deposits;
    mapping(bytes32 => bool) public withdrawals;
    
    uint256 public withdrawalFee = 10; 
    uint256 public accumulatedFees = 0;

    uint256 public constant MAX_WITHDRAWAL_FEE = 30;
    uint256 public constant FEE_DENOMINATOR = 1000;
    
    constructor(){}

    function deposit(bytes32 commit) payable external {
        require(msg.value == 0.1 ether || msg.value == 0.2 ether || msg.value == 0.5 ether || 
            msg.value == 1 ether || msg.value == 10 ether, "HushMixer: deposit amount invalid");
        require(deposits[commit] == false, "HushMixer: commit already deposited");
        deposits[commit] = true;
    }
    
    function withdraw(bytes32 key, address payable receiver, uint256 amount) external onlyOwner {
        require(withdrawals[key] == false, "HushMixer: deposit already withdrawn");
        require(amount == 0.1 ether || amount == 0.2 ether || amount == 0.5 ether || 
            amount == 1 ether || amount == 10 ether, "HushMixer: withdraw amount invalid");
        uint256 fees = amount * withdrawalFee / FEE_DENOMINATOR;
        if(fees > 0){
            accumulatedFees+= fees;
            amount-=fees;
        }
        receiver.transfer(amount);
        withdrawals[key] = true;
    }

    function updateFee(uint256 newWithdrawalFeeBase1000) external onlyOwner {        
        require(newWithdrawalFeeBase1000 <= MAX_WITHDRAWAL_FEE, 
            "HushMixer: excessive fee rate (max 3%)");
        withdrawalFee = newWithdrawalFeeBase1000;
    }

    function claimFees() external onlyOwner {       
        require(accumulatedFees > 0, "HushMixer: no fees to claim");
        payable(owner()).transfer(accumulatedFees);
        accumulatedFees = 0;
    }
}