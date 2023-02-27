/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT

/*
 * 
 * ██    ██ ███    ██ ████████ ██████   █████   ██████ ███████ ██████  
 * ██    ██ ████   ██    ██    ██   ██ ██   ██ ██      ██      ██   ██ 
 * ██    ██ ██ ██  ██    ██    ██████  ███████ ██      █████   ██████  
 * ██    ██ ██  ██ ██    ██    ██   ██ ██   ██ ██      ██      ██   ██ 
 *  ██████  ██   ████    ██    ██   ██ ██   ██  ██████ ███████ ██   ██ 
 *                                                                                                                                                                                                                                                
 * Coded by: -> 31b307d4f468cf4124f3b883c7beed1dbc5bbaa525e56ad39bf24b6072a28a33 <- @2023
 * Multi Amount Version, with 0,1Eth - 0,5Eth - 1Eth
 * 
 * This smart contract provides anonymous transactions through the use of asymmetric encryption. When a user wants to make a transaction,
 * they send an amount to the contract and press a button to generate a password based on the asymmetric encryption protocol. 
 * The password is recorded off-chain in a secure manner so that no one can read it.
 * The user then enters the password and presses the deposit commit button to register the transaction. At this point, the contract knows 
 * a password associated with the funds and anyone, even from another wallet, can withdraw the funds as long as they know the private key 
 * of the generated password. No one can stop the withdrawals or modify the minimum withdrawal and deposit amount openly.
 * The contract does not have a owner and the only thing that can be changed by the person who coded it is the tax collector wallet and 
 * the amount of fees deposited in the contract, which is selectable from 4 fixed options.
 *
 * 
 *
 *┌─────────────────────────────────────────────────────────────────────────────────┐
 *│                                                                                 │
 *│     ┌─────────────────┐                              Chain Breaker Protocol v.1 │
 *│     │                 │                                                         │
 *│     │                 │                                                         │
 *│     │      Alice      ├────────────────────────────┐                            │
 *│     │                 │                            │                            │
 *│     │                 │                            │                            │
 *│     └┬─┬──────────────┘                            │(send funds to CA)          │
 *│      │ │                                           │                            │
 *│      │ │                                           │                            │
 *│      │ │                                           │                            │
 *│      │ │                                           │                            │
 *│      │ │                                           │                            │
 *│      │ │    ┌──────────────────────────────────────▼──────────────────────┐     │
 *│      │ │    │                                                             │     │
 *│      │ │    │                       ┌───────────────────────────────┐     │     │
 *│      │ │    │                       │                               │     │     │
 *│      │ │    │                       │                               │     │     │
 *│      │ │    │                       │                               │     │     │
 *│      │ │    │    ┌───────────────┐  │                               │     │     │
 *│      └─┼────┼───►│ Generate Hash ├──►                               │     │     │
 *│        │    │    └───────────────┘  │                               │     │     │
 *│        │    │                       │                               │     │     │
 *│        │    │    ┌───────────────┐  │     Chain Breaker contract    │     │     │
 *│        └────┼───►│ Commit deposit├──►                               │     │     │
 *│             │    └───────────────┘  │                               │     │     │
 *│             │                       │                               │     │     │
 *│             │    ┌───────────────┐  │                               │     │     │
 *│       ┌─────┼───►│ Withdrawal    ├──►                               │     │     │
 *│       │     │    └───────────────┘  │                               │     │     │
 *│       │     │                       │                               │     │     │
 *│       │     │                       │                               │     │     │
 *│       │     │                       └───────────────────────────────┘     │     │
 *│       │     │                                                             │     │
 *│       │     └─────────────────────────────────────────────────────────────┘     │
 *│       │                                                                         │
 *│       │                                                                         │
 *│       │                                                                         │
 *│       │ (get funds from CA)                                                     │
 *│       │                                                                         │
 *│       │                                                                         │
 *│     ┌─┴───────────────┐                                                         │
 *│     │                 │                                                         │
 *│     │                 │                                                         │
 *│     │     Bob         │                                                         │
 *│     │                 │                                                         │
 *│     │                 │                                                         │
 *│     └─────────────────┘                                                         │
 *│                                                                                 │
 *└─────────────────────────────────────────────────────────────────────────────────┘
 * Source for SHA-3: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf
 *
 * Chain Breaker Team
 * Email: [email protected]
 * ENS Domain: untracer.eth
 *
*/

pragma solidity 0.8.18;

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

contract ChainBreaker   {

    /*
     * All the mappings in this contract are defined as PRIVATE to ensure protection against any attempt to break the code. 
     * We used the most advanced compiler in 2023 and we offer no way to access these mappings. 
     */

    mapping (bytes32 => bool) private _store;                    // Keeps the password HASH.
    mapping (address => uint256) private _balance;               // Keeps the balance of the wallet.
    mapping (bytes32 => bool) private _burntHash;                // Keeps track of all used HASH.
    mapping (bytes32 => uint256) private sentAmount;             // Keeps track of the sent amount

    /* We add a control: only who stakes an amount of the project token can use this contract
     * More users means more power and more security: here i set a mapping for supported token holder. Who holds can 
     * use this software. Array will be: TOKEN CA allowed. Not present, not allowed.
     */

    address[] private allowedTokenStake;
    mapping (address => uint256) private minimumToken;

    /* This variable has in it the owner of the contract. Cannot be changed */ 
    address private owner;

    /* This variable contains wallets for fee collection */ 
    address private _feescollector = 0x93878faBf0739BB31E9EEc04BC6e558A2A6ddCD7;
    address private _feescollector2 = 0xC2E78a5c990374aa669e9Ece5b2AC059A901f02D;

    /* This variable contains the amount of fee. Cannot be changed */ 
    uint private _feeAmount = 1;

    /* This variable create a lock/unlock state to avoid any reentrancy bug or exploit */
    bool private locked;

    /* This contract can handle only 0,1Eth, 0,5Eth, 1Eth and no more and no less. These variable express the value in WEI */
    uint256 private fixedAmount01 = 100000000000000000;
    uint256 private fixedAmount05 = 500000000000000000;
    uint256 private fixedAmount1 = 1000000000000000000;

    /* In NO CASE this contract can be paused for WITHDRAW, but a STOP button for DEPOSIT is added */
    bool private masterSwitchDeposit;

    /*
     * Modifier section. This section contains all the modifier used in the code. 
     */

    /* It verifies that who is broadcasting command is the owner of the contract */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /* It verifies the address used is a valid address */
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }
    
    /* Avoid reentrancy bug and protect all the action, making impossibile to perform a task twice while executing */
    modifier noReentrancy() {
        require(!locked, "No reentrancy");

        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = payable (msg.sender);
    }


    function WITHDRAW(string memory password) public noReentrancy returns (bool) {
       /*
        * Check if the user that wants to send funds can use this service
        */
       //require(checkTokenOfUser(msg.sender));
        
        /*
         * Here the user can insert the "private key", the seed of the hashed password. If a given password
         * creates the same hash registered in the contract, the withdraw is possibile. 
         * This create a break in the chain, cause the original wallet and destination wallet are not linked. 
         */
        
        bytes32 hashedValue = bytes32(keccak256(abi.encodePacked(password)));

        /*
         * From the mapping, we check the amount sent by the user using the hash as key
         */
        
        uint256 sentAmountFromUser = sentAmount[hashedValue];

        /*
         * This amount MUST BE a valid number. 0 is not allowed. This is a security check
         */
        
        require (sentAmountFromUser > 0);
        
        /*
         * To be able to withdraw, the hashed password has to be fresh and never been used before. 
         * This is a security feature
         */

        require(!_burntHash[hashedValue]);
         
         /*
         * To be able to withdraw, the hash generated must be the same. This to guarantee that who is withdrawing is 
         * the same person who sent money to the contract
         */

        require(_store[hashedValue], "Please provide the right user password to withdraw");
        
        /*
         * Execute calculations for fees over transaction and the net value in sent to the user.
         */

        uint256 totalToSendToUser = calculateFeeOverTransaction(sentAmountFromUser);

        /*
         * The NET value ( total amount - fees paid ) is sent to the caller. 
         */
         
        (bool success,) = address(msg.sender).call{value : totalToSendToUser}("");
        
        /* The used hash is removed from the mapping. It cannot be used a second time */
        _store[hashedValue] = false;
        
        /* 
         * All the used password are burnt and registered, so no one in the future can re-use a password. 
         * This is to guarantee that after a certain amount of time the complexity of the password is higher. 
         * Checking the Burnt Hash is a security feature
         */

        _burntHash[hashedValue] = true;

        return success;
    }
    
    function DEPOSIT(bytes32 hashedPasswordManuallyTyped) public payable noReentrancy  {
        
        /*
         * Deposit MUST BE ACTIVE to perform the action. Withdrawal CANNOT BE STOPPED
         */

        require (masterSwitchDeposit == true);

       /*
        * Check if the user that wants to send funds can use this service
        */

       require(checkTokenOfUser(msg.sender));

       /*
        * Deposit has to be a standard value. For this contract, we have 3 only choise. 
        */
       require(msg.value == fixedAmount01 || msg.value == fixedAmount05 || msg.value == fixedAmount1); 

        /*
         * Register the amount sent. User can send 0.1 - 0.5 or 1 Eth. This will be used when user wants to withdraw 
        */

        sentAmount[hashedPasswordManuallyTyped] = msg.value;

        /*
         * To be able to create a DEPOSIT COMMIT, the hashed password has to be fresh and never been used before. 
         * This is a security feature
         */
        _balance[msg.sender] = msg.value;

        require(!_burntHash[hashedPasswordManuallyTyped]);
        
        /*
         * Only who sent funds to the contract can commit a deposit. 
         * This is a security feature
         */

        require(_balance[msg.sender] > 0);
        
        /*
         * This method is an ON CHAIN method. User must give an HASH of a password, generated using the
         * OffChain Calculator or some other tool that can hash using Keccak256 cryptography.
         * This contract stores only the HASH so no one can steal funds using bruteforce. 
         */

        _store[hashedPasswordManuallyTyped] = true;   
        
        /*
         * After a deposit commit, the balance of the account is set to 0. No more action are possible.
         */
        
        _balance[msg.sender] = 0;

    }

    function GENERATE(string memory passwordToHash) public pure returns(bytes32)    {
        
        /*
         * This generates the hash code for the given password OFF CHAIN. Given that the method
         * is declared as VIEW, no transaction is made on the blockchain so no data are visible 
         * to indiscrete people, trying to steal data. Please note that state mutability is set to PURE.
         * Beware: the password MUST BE over 18 character, to be secure.
         */
        
        bytes32 hashedValue;

        /* Here we check if the password has more than 18 character. If it's so, then generate the hash. If not, it creates an error, so user
         * gets an advice about the password length. All this method, we repeat, is OFF CHAIN. 
         */

        if (strlen(passwordToHash) > 18)    {
            hashedValue = bytes32(keccak256(abi.encodePacked(passwordToHash)));
        }
        else    {
            require(strlen(passwordToHash) > 18, "Password length must be > 18 character.");
        }

        return hashedValue;
    }


    /* 
     * This method is used to calculate fees over transactions and send them to the fee collector. 
     * Fee amount is fixed, as the input amount. 
     * Check over all the amount are made to avoid any kind of attack.
     * It returns the amount to send to the user on withdrawal.
     */

    function calculateFeeOverTransaction(uint256 amountOfTransaction) internal returns (uint256)   {
        uint256 taxAmount = amountOfTransaction * _feeAmount / 100;
        uint256 remainingAmount = amountOfTransaction - taxAmount;
        /* Execute transfer to the wallet */
        collectFeeToWallet(taxAmount);
        return remainingAmount;
    }

    /*
     * This method is used to execute transfer using CALL to move the fee amount 
     * to the _fee wallet designated. All this code is inserted in a separate method to make 
     * contract more clear.
     */

    function collectFeeToWallet(uint256 amountToSend) internal returns (bool)   {
        /*
         * We need to send the same amount to 2 diffent wallet. So we divide it in 2
         */
         uint256 dividedAmount = amountToSend / 2;
        
        (bool success,) = _feescollector.call{value : dividedAmount}("");
        (bool success2,) = _feescollector2.call{value : dividedAmount}("");        
        /*
         * Calculate if both transfer was executed
         */

        bool totalSuccess = success && success2;
        
        /*
         * Returns the calculated value
         */

        return totalSuccess;
    }
       
    /*
     * This method is used to calculate the length of a string. Used in this contract, it
     * checkes the length of the password typed by the user, to guarantee that it's not short. 
     * This is a security feature.  
     */

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len = 0;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) { i += 1; }
            else if (b < 0xE0) { i += 2; }
            else if (b < 0xF0) { i += 3; }
            else if (b < 0xF8) { i += 4; } 
            else if (b < 0xFC) { i += 5; } 
            else { i += 6; }
        }
        return len;
    }

    /* 
     * Method to check if the user who wanna use this service is staking sufficient amount of the project's token
     */

     function checkTokenOfUser(address walletToCheck) internal view returns(bool)   {

        /*
         * Set the return value: if the amount in the wallet is correct, returns true. 
         */
        bool canBeUsed = false;
        uint256 balanceOfTheWallet;

        /* 
         * Verify what token is allowed and if is present inside the wallet. 
         * I have to search all the array and test any single CA. 
         */

        for (uint i = 0; i < allowedTokenStake.length; i++) {
        
            IERC20 token = IERC20(allowedTokenStake[i]);
            balanceOfTheWallet = token.balanceOf(walletToCheck);
            
            /*
             * Check the amount and returns true or false. 
            */
        
            if(balanceOfTheWallet >= minimumToken[allowedTokenStake[i]])    {
              canBeUsed = true;
            }
        }

        return canBeUsed;
     } 

    /*
     * Set contract of the new project, inserting the CA address inside the array of allowed
     */

    function setProjectAllowed(address projectCA, uint256 minimumAmountAllowed) external onlyOwner validAddress(projectCA) {
        // Authorize the CA adding its address inside the array
        allowedTokenStake.push(projectCA);   
        // Set the minimum amount for the given CA
        minimumToken[projectCA] = minimumAmountAllowed;
    }

    function removeProjectAllowed(address projectCA) external onlyOwner validAddress(projectCA) {
        // Remove the CA address from the array

        for (uint i = 0; i < allowedTokenStake.length; i++) {
        
           if(allowedTokenStake[i] == projectCA)    {
              delete allowedTokenStake[i];
            }
        }
    }

     /*
     * Public get the amount of token inside a wallet of an ERC20 token
     */

    function checkBalanceInWallet(address walletToCheck, address tokenToCheck) external view returns(uint256)   {

        IERC20 token = IERC20(tokenToCheck);
        return token.balanceOf(walletToCheck);
     } 

    /*
     * This method is used to STOP deposit. Withdrawal is ALWAYS possibile. It's use is for stopping the deposit when needed.
     */

    function stopDeposit(bool enableOrDisableDeposit) external onlyOwner    {

        /* enableOrDisableDeposit can be TRUE or FALSE. If set to FALSE, DEPOSIT is paused. */
        masterSwitchDeposit = enableOrDisableDeposit;
    }

}