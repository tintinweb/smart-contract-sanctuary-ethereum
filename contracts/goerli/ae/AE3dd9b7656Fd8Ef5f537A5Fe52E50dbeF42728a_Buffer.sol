// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IGroupFactory {
    function getWithdrawFee() external view returns (uint256);
}

import "Initializable.sol";
import "ReentrancyGuard.sol";
import "GroupFactory.sol";

contract Buffer is Initializable, ReentrancyGuard {
    uint256 public totalReceived;
    uint256 public royaltyFeePercent;
    uint256 private montageShare;
    uint256 private montageFee;
    string private validKey;
    address public marketWallet; // wallet address for market fee
    address public owner;
    IGroupFactory public interfaceFactory;
    uint256 public withdrawalFee;
    

    error Unauthorized(address caller);
    error InvalidDataInput(uint256 expectedVal, uint256 realVal);
    error InvalidKey();

    event UpdateFeeCheck(uint256 feePercent);
    event WithdrawnCheck(address to, uint256 amount);
    event UpdateSharesCheck(uint256[] share);
    event FeeReceived(address to, uint256 amount);

    modifier onlyOwner() {
		_checkOwner();
		_;
    }

    function _checkOwner() internal view virtual {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
    }

    //============ Function to Receive ETH ============
    receive() external payable {
        totalReceived += msg.value;
        montageFee = msg.value * montageShare / 10000;
        _transfer(marketWallet, montageFee);
        montageFee  = 0;
        emit FeeReceived(address(this), msg.value);
    }
    //============ Function to Transfer Ownership ============
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    //============ Function to Update Valid Key ============
    function updateValidKey(string calldata _valid) external onlyOwner {
        validKey = _valid;
    }
    //============ Function to Withdraw ETH ============
    function withdraw(string calldata _validKey, uint256 _shareAmount, address _factoryAddress) external nonReentrant {
        if (keccak256(abi.encodePacked(_validKey)) != keccak256(abi.encodePacked(validKey))) {
            revert InvalidKey();
        }
        
        interfaceFactory = IGroupFactory(_factoryAddress);
       
        uint256 Fee = interfaceFactory.getWithdrawFee();

        address account = msg.sender;
        if (_shareAmount <= Fee) { // updated to retrieve withdraw fee from Factory.sol
            revert
            InvalidDataInput(Fee, _shareAmount);
        }

    

    _transfer(account, _shareAmount - Fee); // updated to retrieve withdraw fee from Factory.sol
    _transfer(marketWallet, Fee); // updated to retrieve withdraw fee from Factory.sol
    emit WithdrawnCheck(account, _shareAmount);
}

//============ Function to Check Withdraw Fee ============
 function getWFee(address _factoryAddress)  public  {

    interfaceFactory = IGroupFactory(_factoryAddress);
       
    withdrawalFee = interfaceFactory.getWithdrawFee();
        
    }

//============ Function to Initialize Contract ============
function initialize(
    address _owner,
    address _marketWallet,
    uint256 _montageShare
   
) public payable initializer {
    montageShare = _montageShare;
    marketWallet = _marketWallet;
    owner = _owner;
    royaltyFeePercent = 1000;
    
}
//============ Function to Update Royalty Fee Percentage ============
function updateFeePercent(uint256 _royaltyFeePercent) public onlyOwner {
    if (_royaltyFeePercent > 10000) {
        revert InvalidDataInput(10000, _royaltyFeePercent);
    }
    royaltyFeePercent = _royaltyFeePercent;
    emit UpdateFeeCheck(royaltyFeePercent);
}

// adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
error TransferFailed();
//============ Function to Transfer ETH to Address ============
function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
        callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
}
}