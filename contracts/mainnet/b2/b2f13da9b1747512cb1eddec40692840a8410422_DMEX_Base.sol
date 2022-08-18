/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

pragma solidity ^0.8.7;

// L1 Contract

/*  INSTRUCTIONS
 *  
 * Adding Margin Token
 * 1. Set token decimals on Base
 * 2. Allow margin token on Custody
 */

/* Interface for ERC20 Tokens */
abstract contract  Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) virtual  public returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
}

/* Interface for pTokens contract */
abstract contract pToken {
    function redeem(uint256 _value, string memory destinationAddress) virtual public returns (bool _success);
    function redeem(uint256 _value, string memory destinationAddress, bytes4 destinationChainId) virtual public returns (bool _success);
}

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes memory _data, uint256 _gas) external returns (bytes32);
    function requireToConfirmMessage(address _contract, bytes memory _data, uint256 _gas) external returns (bytes32);
    function sourceChainId() external view returns (uint256);
    function destinationChainId() external view returns (uint256);
}

interface DMEXXDAI {
    function depositTokenForUser(address token, uint128 amount, address user) external;
}

// The DMEX base Contract
contract DMEX_Base {
    address public owner; // holds the address of the contract owner
    mapping (address => bool) public admins; // mapping of admin addresses
    address public AMBBridgeContract;
    address public DMEX_XDAI_CONTRACT;

    uint256 public inactivityReleasePeriod; // period in blocks before a user can use the withdraw() function

    bool public destroyed = false; // contract is destoryed
    uint256 public destroyDelay = 1000000; // number of blocks after destroy, the contract is still active (aprox 6 monthds)
    uint256 public destroyBlock;

    uint256 public ambInstructionGas = 2000000;

    mapping (bytes32 => bool) public processedMessages; // records processed bridge messages, so the same message is not executed twice
    mapping (address => bool) public allowedTokens; // mapping of allowed margin tokens

    
    /**
     *
     *  BALNCE FUNCTIONS
     *
     **/

    // Deposit ETH to contract
    function deposit() public payable {
        if (destroyed) revert("Contract destroyed");
        
        sendDepositInstructionToAMBBridge(msg.sender, address(0), msg.value);
    }

    // Deposit token to contract
    function depositToken(address token, uint256 amount) public {
        require(!destroyed, "Contract destroyed");
        require(Token(token).transferFrom(msg.sender, address(this), amount), "Unable to transfer token, chack allowance"); // attempts to transfer the token to this contract, if fails throws an error
        // sendDepositInstructionToAMBBridge(msg.sender, token, amount);
    }

    // Deposit token to contract for a user
    function depositTokenForUser(address token, uint256 amount, address user) public {    
        require(!destroyed, "Contract destroyed");    

        require(Token(token).transferFrom(msg.sender, address(this), amount), "Unable to transfer token, check allowance"); // attempts to transfer the token to this contract, if fails throws an error
        sendDepositInstructionToAMBBridge(user, token, amount);
    }


    function pTokenRedeem(address token, uint256 amount, string memory destinationAddress) public onlyAMBBridge returns (bool success) {
        if (!pToken(token).redeem(amount, destinationAddress)) revert("Redeem failed");
        bytes32 msgId = IAMB(AMBBridgeContract).messageId();
        processedMessages[msgId] = true;
        emit pTokenRedeemEvent(token, msg.sender, amount, destinationAddress);
    }

    function pTokenRedeemV2(address token, uint256 amount, string memory destinationAddress, bytes4 destinationChainId) public onlyAMBBridge returns (bool success) {
        if (!pToken(token).redeem(amount, destinationAddress, destinationChainId)) revert("Redeem failed");
        bytes32 msgId = IAMB(AMBBridgeContract).messageId();
        processedMessages[msgId] = true;
        emit pTokenRedeemEvent(token, msg.sender, amount, destinationAddress);
    }


    function sendDepositInstructionToAMBBridge(address user, address token, uint256 amount) internal
    {
        bytes4 methodSelector = DMEXXDAI(address(0)).depositTokenForUser.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, token, amount, user);

        uint256 gas = ambInstructionGas;

        // send AMB bridge instruction
        bytes32 msgId = IAMB(AMBBridgeContract).requireToPassMessage(DMEX_XDAI_CONTRACT, data, gas);

        emit Deposit(token, user, amount, msgId); // fires the deposit event
    }    
 


    // Withdrawal function called by the Gnosis Bridge
    function withdrawForUser(
        address token, // the address of the token to be withdrawn
        uint256 amount, // the amount to be withdrawn
        address payable user // address of the user
    ) public onlyAMBBridge returns (bool success) {
        if (token == address(0)) { // checks if the withdrawal is in ETH or Tokens
            if (!user.send(amount)) revert(); // sends ETH
        } else {
            if (!Token(token).transfer(user, amount)) revert(); // sends tokens
        }

        bytes32 msgId = IAMB(AMBBridgeContract).messageId();
        processedMessages[msgId] = true;
        emit Withdraw(token, user, amount, msgId); // fires the withdraw event
    }



    /**
     *
     *  HELPER FUNCTIONS
     *
     **/

    // Event fired when the owner of the contract is changed
    event SetOwner(address indexed previousOwner, address indexed newOwner);

    // Allows only the owner of the contract to execute the function
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // Changes the owner of the contract
    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }

    // Owner getter function
    function getOwner() public returns (address out) {
        return owner;
    }

    // Adds or disables an admin account
    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        admins[admin] = isAdmin;
    }


    // Allows for admins only to call the function
    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) revert();
        _;
    }


    // Allows for AMB Bridge only to call the function
    modifier onlyAMBBridge {
        if (msg.sender != AMBBridgeContract) revert();

        bytes32 msgId = IAMB(AMBBridgeContract).messageId();
        require(!processedMessages[msgId], "Error: message already processed");
        _;
    }

    fallback() external {
        revert();
    }

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) public returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) public returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) public returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }



    /**
     *
     *  ADMIN FUNCTIONS
     *
     **/
    // Deposit event fired when a deposit takes place
    event Deposit(address indexed token, address indexed user, uint256 amount, bytes32 msgId);

    // Withdraw event fired when a withdrawal id executed
    event Withdraw(address indexed token, address indexed user, uint256 amount, bytes32 msgId);
    
    // pTokenRedeemEvent event fired when a pToken withdrawal is executed
    event pTokenRedeemEvent(address indexed token, address indexed user, uint256 amount, string destinationAddress);

    // Change inactivity release period event
    event InactivityReleasePeriodChange(uint256 value);

    // Fee account changed event
    event FeeAccountChanged(address indexed newFeeAccount);

    // Margin token allowed
    event MarginTokenAllow(address indexed token, bool allow);



    // Constructor function, initializes the contract and sets the core variables
    constructor(uint256 inactivityReleasePeriod_, address AMBBridgeContract_, address DMEX_XDAI_CONTRACT_) {
        owner = msg.sender;
        inactivityReleasePeriod = inactivityReleasePeriod_;
        AMBBridgeContract = AMBBridgeContract_;
        DMEX_XDAI_CONTRACT = DMEX_XDAI_CONTRACT_;
    }

    // Sets the inactivity period before a user can withdraw funds manually
    function destroyContract() public onlyOwner returns (bool success) {
        if (destroyed) revert();
        destroyBlock = block.number;

        return true;
    }

    // Sets the inactivity period before a user can withdraw funds manually
    function setInactivityReleasePeriod(uint256 expiry) public onlyOwner returns (bool success) {
        if (expiry > 1000000) revert();
        inactivityReleasePeriod = expiry;

        emit InactivityReleasePeriodChange(expiry);
        return true;
    }

    // Returns the inactivity release perios
    function getInactivityReleasePeriod() public view returns (uint256)
    {
        return inactivityReleasePeriod;
    }


    function releaseFundsAfterDestroy(address token, uint256 amount) public onlyOwner returns (bool success) {
        if (!destroyed) revert();
        if (safeAdd(destroyBlock, destroyDelay) > block.number) revert(); // destroy delay not yet passed

        if (token == address(0)) { // checks if withdrawal is a token or ETH, ETH has address 0x00000... 
            if (!payable(msg.sender).send(amount)) revert(); // send ETH
        } else {
            if (!Token(token).transfer(msg.sender, amount)) revert(); // Send token
        }
    }

    function setAmbInstructionGas(uint256 newGas) public onlyOwner {
        ambInstructionGas = newGas;
    }

    // Chamge allowed margin tokens
    function allowMarginToken(address token, bool alw) public onlyOwner
    {
        allowedTokens[token] = alw;
        emit MarginTokenAllow(token, alw);
    }
}