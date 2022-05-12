/* solium-disable-next-line linebreak-style */
pragma solidity ^0.4.24;

// Implements a simple ownership model with 2-phase transfer.
contract Owned {

    address public owner;
    address public proposedOwner;

    constructor() public
    {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender) == true, 'Require owner to execute transaction');
        _;
    }


    function isOwner(address _address) public view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool success) {
        require(_proposedOwner != address(0), 'Require proposedOwner != address(0)');
        require(_proposedOwner != address(this), 'Require proposedOwner != address(this)');
        require(_proposedOwner != owner, 'Require proposedOwner != owner');

        proposedOwner = _proposedOwner;
        return true;
    }


    function completeOwnershipTransfer() public returns (bool success) {
        require(msg.sender == proposedOwner, 'Require msg.sender == proposedOwner');

        owner = msg.sender;
        proposedOwner = address(0);

        return true;
    }
}

// ----------------------------------------------------------------------------
// OpsManaged - Implements an Owner and Ops Permission Model
// ----------------------------------------------------------------------------
contract OpsManaged is Owned {

    address public opsAddress;


    constructor() public
        Owned()
    {
    }


    modifier onlyOwnerOrOps() {
        require(isOwnerOrOps(msg.sender), 'Require only owner or ops');
        _;
    }


    function isOps(address _address) public view returns (bool) {
        return (opsAddress != address(0) && _address == opsAddress);
    }


    function isOwnerOrOps(address _address) public view returns (bool) {
        return (isOwner(_address) || isOps(_address));
    }


    function setOpsAddress(address _newOpsAddress) public onlyOwner returns (bool success) {
        require(_newOpsAddress != owner, 'Require newOpsAddress != owner');
        require(_newOpsAddress != address(this), 'Require newOpsAddress != address(this)');

        opsAddress = _newOpsAddress;

        return true;
    }
}

// ----------------------------------------------------------------------------
// Finalizable - Implement Finalizable (Crowdsale) model
// ----------------------------------------------------------------------------
contract Finalizable is OpsManaged {

    FinalizableState public finalized;
    
    enum FinalizableState { 
        None,
        Finalized
    }

    event Finalized();


    constructor() public OpsManaged()
    {
        finalized = FinalizableState.None;
    }


    function finalize() public onlyOwner returns (bool success) {
        require(finalized == FinalizableState.None, 'Require !finalized');

        finalized = FinalizableState.Finalized;

        emit Finalized();

        return true;
    }
}

// ----------------------------------------------------------------------------
// Math - Implement Math Library
// ----------------------------------------------------------------------------
library Math {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 r = a + b;

        require(r >= a, 'Require r >= a');

        return r;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, 'Require a >= b');

        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 r = a * b;

        require(r / a == b, 'Require r / a == b');

        return r;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC20Interface - Standard ERC20 Interface Definition
// Based on the final ERC20 specification at:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// ----------------------------------------------------------------------------
// ERC20Token - Standard ERC20 Implementation
// ----------------------------------------------------------------------------
contract ERC20Token is ERC20Interface {

    using Math for uint256;

    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) allowed;


    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _initialTokenHolder) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        // The initial balance of tokens is assigned to the given token holder address.
        balances[_initialTokenHolder] = _totalSupply;
        allowed[_initialTokenHolder][_initialTokenHolder] = balances[_initialTokenHolder];

        // Per EIP20, the constructor should fire a Transfer event if tokens are assigned to an account.
        emit Transfer(0x0, _initialTokenHolder, _totalSupply);
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) { 
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            emit Transfer(msg.sender, _to, _value);

            return true;
        } else { 
            return false;
        }
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            emit Transfer(_from, _to, _value);

            return true;
        } else { 
            return false;
        }
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}

// ----------------------------------------------------------------------------
// FinalizableToken - Extension to ERC20Token with ops and finalization
// ----------------------------------------------------------------------------

//
// ERC20 token with the following additions:
//    1. Owner/Ops Ownership
//    2. Finalization
//
contract FinalizableToken is ERC20Token, OpsManaged, Finalizable {

    using Math for uint256;


    // The constructor will assign the initial token supply to the owner (msg.sender).
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public
        ERC20Token(_name, _symbol, _decimals, _totalSupply, msg.sender)
        Finalizable()
    {
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to);

        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        validateTransfer(msg.sender, _to);

        return super.transferFrom(_from, _to, _value);
    }


    function validateTransfer(address _sender, address _to) internal view {
        // Once the token is finalized, everybody can transfer tokens.
        if (finalized == FinalizableState.Finalized) {
            return;
        }
        

        if (isOwner(_to)) {
            return;
        }

        // Before the token is finalized, only owner and ops are allowed to initiate transfers.
        // This allows them to move tokens while the sale is still in private sale.
        require(isOwnerOrOps(_sender), 'Require is owner or ops allowed to initiate transfer');
    }
}



// ----------------------------------------------------------------------------
// PBTT Token Contract Configuration
// ----------------------------------------------------------------------------
contract PBTTTokenConfig {

    string  internal constant TOKEN_SYMBOL      = 'PBTT';
    string  internal constant TOKEN_NAME        = 'Purple Butterfly Token (PBTT)';
    uint8   internal constant TOKEN_DECIMALS    = 3;

    uint256 internal constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 internal constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}


// ----------------------------------------------------------------------------
// PBTT Token Contract
// ----------------------------------------------------------------------------
contract PBTTToken is FinalizableToken, PBTTTokenConfig {
      
    uint256 public buyPriceEth = 0.0002 ether;                              // Buy price for PBTT
    uint256 public sellPriceEth = 0.0001 ether;                             // Sell price for PBTT
    uint256 public gasForPBTT = 0.005 ether;                                // Eth from contract against PBTT to pay tx (10 times sellPriceEth)
    uint256 public PBTTForGas = 1;                                          // PBTT to contract against eth to pay tx
    uint256 public gasReserve = 1 ether;                                    // Eth amount that remains in the contract for gas and can't be sold

    // Minimal eth balance of sender and recipient, ensure that no account receiving
    // the token has less than the necessary Ether to pay the fees
    uint256 public minBalanceForAccounts = 0.005 ether;                     
    uint256 public totalTokenSold = 0;
    
    enum HaltState { 
        Unhalted,
        Halted        
    }

    HaltState public halts;

    constructor() public
        FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY)
    {
        halts = HaltState.Unhalted;
        finalized = FinalizableState.None;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(halts == HaltState.Unhalted, 'Require smart contract is not in halted state');

        // Prevents drain and spam
        require(_value >= PBTTForGas, 'Token amount is not enough to transfer'); 
         
        if (!isOwnerOrOps(msg.sender) && _to == address(this)) {
            // Trade PBTT against eth by sending to the token contract
            sellPBTTAgainstEther(_value);                             
            return true;
        } else {
            if(isOwnerOrOps(msg.sender)) {
                return super.transferFrom(owner, _to, _value);
            }
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(halts == HaltState.Unhalted, 'Require smart contract is not in halted state');
        return super.transferFrom(_from, _to, _value);
    }
    
    //Change PPBT Selling and Buy Price
    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) public onlyOwnerOrOps {
        // Set prices to buy and sell PBTT
        buyPriceEth = newBuyPriceEth;                                       
        sellPriceEth = newSellPriceEth;
    }

    function setGasForPBTT(uint256 newGasAmountInWei) public onlyOwnerOrOps {
        gasForPBTT = newGasAmountInWei;
    }

    //set PBTT to contract against eth to pay tx
    function setPBTTForGas(uint256 newPBTTAmount) public onlyOwnerOrOps {
        PBTTForGas = newPBTTAmount;
    }

    function setGasReserve(uint256 newGasReserveInWei) public onlyOwnerOrOps {
        gasReserve = newGasReserveInWei;
    }

    function setMinBalance(uint256 minimumBalanceInWei) public onlyOwnerOrOps {
        minBalanceForAccounts = minimumBalanceInWei;
    }

    function getTokenRemaining() public view returns (uint256 total){
        return (TOKEN_TOTALSUPPLY.div(DECIMALSFACTOR)).sub(totalTokenSold);
    }

    /* User buys PBTT and pays in Ether */
    function buyPBTTAgainstEther() private returns (uint256 tokenAmount) {
        // Avoid dividing 0, sending small amounts and spam
        require(buyPriceEth > 0, 'buyPriceEth must be > 0');
        require(msg.value >= buyPriceEth, 'Transfer money must be enough for 1 token');
        
        // Calculate the amount of PBTT
        tokenAmount = (msg.value.mul(DECIMALSFACTOR)).div(buyPriceEth);                
        
        // Check if it has enough to sell
        require(balances[owner] >= tokenAmount, 'Not enough token balance');
        
        // Add the amount to buyer's balance
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);            

        // Subtract amount from PBTT balance
        balances[owner] = balances[owner].sub(tokenAmount);

        // Execute an event reflecting the change
        emit Transfer(owner, msg.sender, tokenAmount);                           
        
        totalTokenSold = totalTokenSold + tokenAmount;
		
        return tokenAmount;
    }

    function sellPBTTAgainstEther(uint256 amount) private returns (uint256 revenue) {
        // Avoid selling and spam
        require(sellPriceEth > 0, 'sellPriceEth must be > 0');
        
        require(amount >= PBTTForGas, 'Sell token amount must be larger than PBTTForGas value');

        // Check if the sender has enough to sell
        require(balances[msg.sender] >= amount, 'Token balance is not enough to sold');
        
        require(msg.sender.balance >= minBalanceForAccounts, 'Seller balance must be enough to pay the transaction fee');
        
        // Revenue = eth that will be send to the user
        revenue = (amount.div(DECIMALSFACTOR)).mul(sellPriceEth);                                 

        // Keep min amount of eth in contract to provide gas for transactions
        uint256 remaining = address(this).balance.sub(revenue);
        require(remaining >= gasReserve, 'Remaining contract balance is not enough for reserved');

        // Add the token amount to owner balance
        balances[owner] = balances[owner].add(amount);         
        // Subtract the amount from seller's token balance
        balances[msg.sender] = balances[msg.sender].sub(amount);            

        // transfer eth
        // 'msg.sender.transfer' means the contract sends ether to 'msg.sender'
        // It's important to do this last to avoid recursion attacks
        msg.sender.transfer(revenue);
 
        // Execute an event reflecting on the change
        emit Transfer(msg.sender, owner, amount);                            
        return revenue;   
    }

    // Allows a token holder to burn tokens. Once burned, tokens are permanently
    // removed from the total supply.
    function burn(uint256 _amount) public returns (bool success) {
        require(_amount > 0, 'Token amount to burn must be larger than 0');

        address account = msg.sender;
        require(_amount <= balanceOf(account), 'You cannot burn token you dont have');

        balances[account] = balances[account].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        return true;
    }

    // Allows the owner to reclaim tokens that are assigned to the token contract itself.
    function reclaimTokens() public onlyOwner returns (bool success) {

        address account = address(this);
        uint256 amount = balanceOf(account);

        if (amount == 0) {
            return false;
        }

        balances[account] = balances[account].sub(amount);
        balances[owner] = balances[owner].add(amount);

        return true;
    }

    // Allows the owner to withdraw that are assigned to the token contract itself.
    function withdrawFundToOwner() public onlyOwner {
        // transfer to owner
        uint256 eth = address(this).balance; 
        owner.transfer(eth);
    }

    // Allows the owner to withdraw all fund from contract to owner's specific adress
    function withdrawFundToAddress(address _ownerOtherAdress) public onlyOwner {
        // transfer to owner
        uint256 eth = address(this).balance; 
        _ownerOtherAdress.transfer(eth);
    }

    /* Halts or unhalts direct trades without the sell/buy functions below */
    function haltsTrades() public onlyOwnerOrOps returns (bool success) {
        halts = HaltState.Halted;
        return true;
    }

    function unhaltsTrades() public onlyOwnerOrOps returns (bool success) {
        halts = HaltState.Unhalted;
        return true;
    }

    function() public payable { 
        if(msg.sender != owner) {
            require(finalized == FinalizableState.Finalized, 'Require smart contract is finalized');
            require(halts == HaltState.Unhalted, 'Require smart contract is not halted');
            
            buyPBTTAgainstEther(); 
        }
    } 

}