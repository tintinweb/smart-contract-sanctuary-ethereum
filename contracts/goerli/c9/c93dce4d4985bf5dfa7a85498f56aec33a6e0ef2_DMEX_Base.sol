/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-02-12
*/

pragma solidity ^0.4.19;

/* Interface for ERC20 Tokens */
contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

/* Interface for pTokens contract */
contract pToken {
    function redeem(uint256 _value, string memory _btcAddress) public returns (bool _success);
}

// The DMEX base Contract
contract DMEX_Base {
    function assert(bool assertion) {
        if (!assertion) throw;
    }

    // Safe Multiply Function - prevents integer overflow
    function safeMul(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow
    function safeSub(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow
    function safeAdd(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    address public owner; // holds the address of the contract owner
    mapping (address => bool) public admins; // mapping of admin addresses
    mapping (address => bool) public futuresContracts; // mapping of connected futures contracts
    event SetFuturesContract(address futuresContract, bool isFuturesContract);

    // Event fired when the owner of the contract is changed
    event SetOwner(address indexed previousOwner, address indexed newOwner);

    // Allows only the owner of the contract to execute the function
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // Changes the owner of the contract
    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }

    // Owner getter function
    function getOwner() returns (address out) {
        return owner;
    }

    // Adds or disables an admin account
    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }


    // Adds or disables a futuresContract address
    function setFuturesContract(address futuresContract, bool isFuturesContract) onlyOwner {
        if (fistFuturesContract == address(0))
        {
            fistFuturesContract = futuresContract;
        }
        else
        {
            revert();
        }

        futuresContracts[futuresContract] = isFuturesContract;

        emit SetFuturesContract(futuresContract, isFuturesContract);
    }

    // Allows for admins only to call the function
    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }

    // Allows for futures contracts only to call the function
    modifier onlyFuturesContract {
        if (!futuresContracts[msg.sender]) throw;
        _;
    }

    function() external {
        throw;
    }

    mapping (address => mapping (address => uint256)) public balances; // mapping of token addresses to mapping of balances and reserve (bitwise compressed) // balances[token][user]

    mapping (address => uint256) public userFirstDeposits; // mapping of user addresses and block number of first deposit

    address public gasFeeAccount; // the account that receives the trading fees
    address public fistFuturesContract; // 0x if there are no futures contracts set yet

    uint256 public inactivityReleasePeriod; // period in blocks before a user can use the withdraw() function
    mapping (bytes32 => bool) public withdrawn; // mapping of withdraw requests, makes sure the same withdrawal is not executed twice

    bool public destroyed = false; // contract is destoryed
    uint256 public destroyDelay = 1000000; // number of blocks after destroy contract still active (aprox 6 monthds)
    uint256 public destroyBlock;

    // Deposit event fired when a deposit takes place
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);

    // Withdraw event fired when a withdrawal id executed
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance, uint256 withdrawFee);

    // pTokenRedeemEvent event fired when a pToken withdrawal is executed
    event pTokenRedeemEvent(address indexed token, address indexed user, uint256 amount, string destinationAddress);

    // Allow futuresContract
    event AllowFuturesContract(address futuresContract, address user);

    // Change inactivity release period event
    event InactivityReleasePeriodChange(uint256 value);

    // Sets the inactivity period before a user can withdraw funds manually
    function setInactivityReleasePeriod(uint256 expiry) onlyOwner returns (bool success) {
        if (expiry > 1000000) throw;
        inactivityReleasePeriod = expiry;

        emit InactivityReleasePeriodChange(expiry);
        return true;
    }

    // Constructor function, initializes the contract and sets the core variables
    function DMEX_Base(address feeAccount_, uint256 inactivityReleasePeriod_) {
        owner = msg.sender;
        gasFeeAccount = feeAccount_;
        inactivityReleasePeriod = inactivityReleasePeriod_;
    }

    // Sets the inactivity period before a user can withdraw funds manually
    function destroyContract() onlyOwner returns (bool success) {
        if (destroyed) throw;
        destroyBlock = block.number;

        return true;
    }

    function updateBalanceAndReserve (address token, address user, uint256 balance, uint256 reserve) private
    {
        uint256 character = uint256(balance);
        character |= reserve<<128;

        balances[token][user] = character;
    }

    function updateBalance (address token, address user, uint256 balance) private returns (bool)
    {
        uint256 character = uint256(balance);
        character |= getReserve(token, user)<<128;

        balances[token][user] = character;
        return true;
    }

    function updateReserve (address token, address user, uint256 reserve) private
    {
        uint256 character = uint256(balanceOf(token, user));
        character |= reserve<<128;

        balances[token][user] = character;
    }

    function decodeBalanceAndReserve (address token, address user) returns (uint256[2])
    {
        uint256 character = balances[token][user];
        uint256 balance = uint256(uint128(character));
        uint256 reserve = uint256(uint128(character>>128));

        return [balance, reserve];
    }


    // Returns the balance of a specific token for a specific user
    function balanceOf(address token, address user) view returns (uint256) {
        //return tokens[token][user];
        return decodeBalanceAndReserve(token, user)[0];
    }

    // Returns the reserved amound of token for user
    function getReserve(address token, address user) public view returns (uint256) {
        //return reserve[token][user];
        return decodeBalanceAndReserve(token, user)[1];
    }

    // Sets reserved amount for specific token and user (can only be called by futures contract)
    function setReserve(address token, address user, uint256 amount) onlyFuturesContract returns (bool success) {
        updateReserve(token, user, amount);
        return true;
    }

    function setBalance(address token, address user, uint256 amount) onlyFuturesContract returns (bool success)     {
        updateBalance(token, user, amount);
        return true;

    }

    function subBalanceAddReserve(address token, address user, uint256 subBalance, uint256 addReserve) onlyFuturesContract returns (bool)
    {
        if (balanceOf(token, user) < subBalance) return false;
        updateBalanceAndReserve(token, user, safeSub(balanceOf(token, user), subBalance), safeAdd(getReserve(token, user), addReserve));
        return true;
    }

    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) onlyFuturesContract returns (bool)
    {
        if (getReserve(token, user) < subReserve) return false;
        updateBalanceAndReserve(token, user, safeAdd(balanceOf(token, user), addBalance), safeSub(getReserve(token, user), subReserve));
        return true;
    }

    function addBalanceAddReserve(address token, address user, uint256 addBalance, uint256 addReserve) onlyFuturesContract returns (bool)
    {
        updateBalanceAndReserve(token, user, safeAdd(balanceOf(token, user), addBalance), safeAdd(getReserve(token, user), addReserve));
    }

    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) onlyFuturesContract returns (bool)
    {
        if (balanceOf(token, user) < subBalance || getReserve(token, user) < subReserve) return false;
        updateBalanceAndReserve(token, user, safeSub(balanceOf(token, user), subBalance), safeSub(getReserve(token, user), subReserve));
        return true;
    }

    // Returns the available balance of a specific token for a specific user
    function availableBalanceOf(address token, address user) view returns (uint256) {
        return safeSub(balanceOf(token, user), getReserve(token, user));
    }

    // Increases the user balance
    function addBalance(address token, address user, uint256 amount) private
    {
        updateBalance(token, user, safeAdd(balanceOf(token, user), amount));
    }

    // Decreases user balance
    function subBalance(address token, address user, uint256 amount) private
    {
        if (availableBalanceOf(token, user) < amount) throw;
        updateBalance(token, user, safeSub(balanceOf(token, user), amount));
    }



    // Returns the inactivity release perios
    function getInactivityReleasePeriod() view returns (uint256)
    {
        return inactivityReleasePeriod;
    }


    // Deposit ETH to contract
    function deposit() payable {
        if (destroyed) revert();

        addBalance(address(0), msg.sender, msg.value); // adds the deposited amount to user balance
        if (userFirstDeposits[msg.sender] == 0) userFirstDeposits[msg.sender] = block.number;
        emit Deposit(address(0), msg.sender, msg.value, balanceOf(address(0), msg.sender)); // fires the deposit event
    }

    // Deposit ETH to contract for a user
    function depositForUser(address user) payable {
        if (destroyed) revert();
        addBalance(address(0), user, msg.value); // adds the deposited amount to user balance
        emit Deposit(address(0), user, msg.value, balanceOf(address(0), user)); // fires the deposit event
    }

    // Deposit token to contract
    function depositToken(address token, uint128 amount) {
        if (destroyed) revert();

        addBalance(token, msg.sender, amount); // adds the deposited amount to user balance

        if (!Token(token).transferFrom(msg.sender, this, amount)) throw; // attempts to transfer the token to this contract, if fails throws an error
        emit Deposit(token, msg.sender, amount, balanceOf(token, msg.sender)); // fires the deposit event
    }

    // Deposit token to contract for a user
    function depositTokenForUser(address token, uint128 amount, address user) {
        addBalance(token, user, amount); // adds the deposited amount to user balance

        if (!Token(token).transferFrom(msg.sender, this, amount)) throw; // attempts to transfer the token to this contract, if fails throws an error
        emit Deposit(token, user, amount, balanceOf(token, user)); // fires the deposit event
    }

    // Deposit token to contract for a user anc charge a deposit fee
    function depositTokenForUserWithFee(address token, uint128 amount, address user, uint256 depositFee) {
        if (safeMul(depositFee, 1e18) / amount > 1e17) revert(); // deposit fee is more than 10% of the deposit amount
        addBalance(token, user, safeSub(amount, depositFee)); // adds the deposited amount to user balance

        addBalance(token, gasFeeAccount, depositFee); // adds the deposit fee to the gasFeeAccount

        if (!Token(token).transferFrom(msg.sender, this, amount)) revert(); // attempts to transfer the token to this contract, if fails throws an error

        emit Deposit(token, user, safeSub(amount, depositFee), balanceOf(token, user)); // fires the deposit event
    }

    function withdraw(address token, uint256 amount) returns (bool success) {

        if (availableBalanceOf(token, msg.sender) < amount) throw;

        subBalance(token, msg.sender, amount); // subtracts the withdrawed amount from user balance

        if (token == address(0)) { // checks if withdrawal is a token or ETH, ETH has address 0x00000...
            if (!msg.sender.send(amount)) throw; // send ETH
        } else {
            if (!Token(token).transfer(msg.sender, amount)) throw; // Send token
        }
        emit Withdraw(token, msg.sender, amount, balanceOf(token, msg.sender), 0); // fires the Withdraw event
    }

    function pTokenRedeem(address token, uint256 amount, string destinationAddress) returns (bool success) {

        if (availableBalanceOf(token, msg.sender) < amount) revert();

        subBalance(token, msg.sender, amount); // subtracts the withdrawal amount from user balance

        if (!pToken(token).redeem(amount, destinationAddress)) revert();
        emit pTokenRedeemEvent(token, msg.sender, amount, destinationAddress);
    }

    function releaseFundsAfterDestroy(address token, uint256 amount) onlyOwner returns (bool success) {
        if (!destroyed) throw;
        if (safeAdd(destroyBlock, destroyDelay) > block.number) throw; // destroy delay not yet passed

        if (token == address(0)) { // checks if withdrawal is a token or ETH, ETH has address 0x00000...
            if (!msg.sender.send(amount)) throw; // send ETH
        } else {
            if (!Token(token).transfer(msg.sender, amount)) throw; // Send token
        }
    }


    // Withdrawal function used by the server to execute withdrawals
    function withdrawForUser(
        address token, // the address of the token to be withdrawn
        uint256 amount, // the amount to be withdrawn
        address user, // address of the user
        uint256 nonce, // nonce to make the request unique
        uint8 v, // part of user signature
        bytes32 r, // part of user signature
        bytes32 s, // part of user signature
        uint256 feeWithdrawal // the transaction gas fee that will be deducted from the user balance
    ) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, token, amount, user, nonce, feeWithdrawal); // creates the hash for the withdrawal request
        if (withdrawn[hash]) throw; // checks if the withdrawal was already executed, if true, throws an error
        withdrawn[hash] = true; // sets the withdrawal as executed
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) != user) throw; // checks that the provided signature is valid

        if (availableBalanceOf(token, user) < amount) throw; // checks that user has enough balance

        subBalance(token, user, amount); // subtracts the withdrawal amount from the user balance

        addBalance(token, gasFeeAccount, feeWithdrawal); // moves the gas fee to the feeAccount

        if (token == address(0)) { // checks if the withdrawal is in ETH or Tokens
            if (!user.send(safeSub(amount, feeWithdrawal))) throw; // sends ETH
        } else {
            if (!Token(token).transfer(user, safeSub(amount, feeWithdrawal))) throw; // sends tokens
        }
        emit Withdraw(token, user, amount, balanceOf(token, user), feeWithdrawal); // fires the withdraw event
    }

    function batchWithdrawForUser(
        address[] token, // the address of the token to be withdrawn
        uint256[] amount, // the amount to be withdrawn
        address[] user, // address of the user
        uint256[] nonce, // nonce to make the request unique
        uint8[] v, // part of user signature
        bytes32[] r, // part of user signature
        bytes32[] s, // part of user signature
        uint256[] feeWithdrawal // the transaction gas fee that will be deducted from the user balance
    ) onlyAdmin
    {
        for (uint i = 0; i < amount.length; i++) {
            withdrawForUser(
                token[i],
                amount[i],
                user[i],
                nonce[i],
                v[i],
                r[i],
                s[i],
                feeWithdrawal[i]
            );
        }
    }

    // Withdrawal function used by the server to execute withdrawals
    function pTokenRedeemForUser(
        address token, // the address of the token to be withdrawn
        uint256 amount, // the amount to be withdrawn
        address user, // address of the user
        string destinationAddress, // the destination address of the user (BTC address for pBTC)
        uint256 nonce, // nonce to make the request unique
        uint8 v, // part of user signature
        bytes32 r, // part of user signature
        bytes32 s, // part of user signature
        uint256 feeWithdrawal // the transaction gas fee that will be deducted from the user balance
    ) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, token, amount, user, nonce, destinationAddress, feeWithdrawal); // creates the hash for the withdrawal request
        if (withdrawn[hash]) throw; // checks if the withdrawal was already executed, if true, throws an error
        withdrawn[hash] = true; // sets the withdrawal as executed
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) != user) throw; // checks that the provided signature is valid

        if (availableBalanceOf(token, user) < amount) throw; // checks that user has enough balance

        subBalance(token, user, amount); // subtracts the withdrawal amount from the user balance

        addBalance(token, gasFeeAccount, feeWithdrawal); // moves the gas fee to the feeAccount

        if (!pToken(token).redeem(amount, destinationAddress)) revert();

        emit pTokenRedeemEvent(token, user, amount, destinationAddress);
    }


    function getMakerTakerBalances(address token, address maker, address taker) view returns (uint256[4])
    {
        return [
            balanceOf(token, maker),
            balanceOf(token, taker),
            getReserve(token, maker),
            getReserve(token, taker)
        ];
    }

    function getUserBalances(address token, address user) view returns (uint256[2])
    {
        return [
            balanceOf(token, user),
            getReserve(token, user)
        ];
    }
}