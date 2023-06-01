/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ShibaInuRaffle {
    address public constant TOKEN_ADDRESS = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address public constant BURN_WALLET = 0x0000000000000000000000000000000000000000;
    address public constant BURN_DEPLOYER = 0xD88365259d00342B02a207A87FaE85DA828A1007;
    
    uint256 public constant MINIMUM_TOKENS = 5910165 * 10**9; // 5910165 Shiba Inu
    uint256 public constant MAXIMUM_TOKENS = 17730496 * 10**9; // 17730496 Shiba Inu
    uint256 public paymentRule = 50;
    uint256 public transactionCount;
    uint256 public totalReceived;
    
    mapping(address => bool) public eligibleSenders;
    
    event TokensSent(address indexed recipient, uint256 amount);
    
    modifier onlyBurnDeployer() {
        require(msg.sender == BURN_DEPLOYER, "Only the Burn Deployer can call this function");
        _;
    }
    
    function updatePaymentRule(uint256 _newPaymentRule) external onlyBurnDeployer {
        paymentRule = _newPaymentRule;
    }
    
    function sendTokens(address[] calldata _recipients, uint256[] calldata _amounts) external onlyBurnDeployer {
        require(_recipients.length == _amounts.length, "Invalid input lengths");
        require(_recipients.length == 2, "Exactly 2 recipients required");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            IERC20(TOKEN_ADDRESS).transfer(_recipients[i], _amounts[i]);
            emit TokensSent(_recipients[i], _amounts[i]);
        }
    }
    
    function processTransaction(address _sender, uint256 _amount) internal {
        require(_amount >= MINIMUM_TOKENS && _amount <= MAXIMUM_TOKENS, "Invalid transaction amount");
        
        if (!eligibleSenders[_sender]) {
            eligibleSenders[_sender] = true;
            transactionCount++;
        }
        
        totalReceived += _amount;
        
        if (transactionCount % paymentRule == 0) {
            address[] memory recipients = new address[](2);
            uint256[] memory amounts = new uint256[](2);
            
            recipients[0] = _randomAddress();
            recipients[1] = _randomAddress();
            amounts[0] = totalReceived * 15 / 100;
            amounts[1] = totalReceived * 15 / 100;
            
            IERC20(TOKEN_ADDRESS).transfer(recipients[0], amounts[0]);
            IERC20(TOKEN_ADDRESS).transfer(recipients[1], amounts[1]);
            emit TokensSent(recipients[0], amounts[0]);
            emit TokensSent(recipients[1], amounts[1]);
            
            totalReceived -= (amounts[0] + amounts[1]);
            
            IERC20(TOKEN_ADDRESS).transfer(BURN_WALLET, totalReceived / 2);
            emit TokensSent(BURN_WALLET, totalReceived / 2);
            totalReceived = 0;
        }
    }
    
    function _randomAddress() internal view returns (address) {
    uint256 randomNonce = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    return address(uint160(uint256(keccak256(abi.encodePacked(randomNonce))))); // Updated type conversion
}

    
    receive() external payable {
        processTransaction(msg.sender, msg.value);
    }
}