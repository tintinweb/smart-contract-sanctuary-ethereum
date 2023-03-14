/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/SageToken.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GnairaToken is IERC20{
    
    // Define the name of token, symbol and total Suppply
    // define the owner of the token
    // see balance, transfer, approve, transfer from, allowance.
    // @dev: For the burn and the mint function to be executed the signers has to confirmTransaction
    //  and executeTransaction

    // Define Variables
    address public governor;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public override totalSupply;
    mapping (address => uint256) private balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public blacklists;

    // MultiSigner
    event createTx(uint indexed txId, address indexed from, address indexed to, uint amount);
    event ApproveTx(address indexed owner, uint indexed txId);
    event RevokeTx(address indexed owner, uint indexed txId);
    event ExecuteTx(uint indexed txId);

    address[] public signers;
    mapping(address => bool) public isSigner;
    uint256 public totalSigner;
    uint256 public numConfirmationsRequired;
    
    struct Transaction{
        address to;
        uint value;
        string name;
        bool executed;
    }
    
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    
    constructor(){
        governor =  msg.sender;
        name = 'G-Naira';
        symbol = 'gNGN';
        decimals = 18;
        totalSupply =  10000000 * 10**18;
        balances[governor] = totalSupply;
    }

     // modifiers
    modifier Onlygovernor(){
        require(msg.sender == governor, "Only Governor has permission");
        _;  
    }

     modifier onlySigner() {
        require(isSigner[msg.sender], "Opps, you are not signer");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Invalid!!, Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }


    // Functions
    function balanceOf(address tokenAddress) public override view returns (uint256){
            return balances[tokenAddress];    
    }
    function transfer(address to, uint256 tokens) public override returns (bool){
        require(blacklists[to] == false, "Your account is blacklisted, Contact the governor");
       require(balances[msg.sender] >= tokens, "Insufficient Token Amount");
        balances[to] += tokens;
        balances[msg.sender] -=  tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(address _owner, address spender) public override  view returns (uint256){
        return allowed[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
       
        require(balances[msg.sender] >= amount,"Insufficient Token Amount");
        allowed[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);

        return true;

    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool){
        require(blacklists[to] == false, "Your account as blacklisted, Contact the governor");
        require(allowed[from][msg.sender] >= amount, "Insufficient Token Amount");
        require(balances[from] >= amount, "Insufficient Token Amount");

        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function addNewsigner(address _multisigner) external Onlygovernor {

        require(_multisigner != address(0), "Invalid Address!");
        require(!isSigner[_multisigner], "Signer Already Exist!");

        isSigner[_multisigner] = true;
        signers.push(_multisigner);
        totalSigner += 1;
        
    }

    function removeSigner(address _multisigner) public Onlygovernor {
        
        require(_multisigner != governor, "Please you cannot remove the governor!");
        require(!isSigner[_multisigner], "Signer does not exist!");

        isSigner[_multisigner] = false;

        for (uint i; i < signers.length; i++) {
                if (signers[i] == _multisigner) {
                    signers[i] = signers[signers.length - 1];
                    break;
                }
        }

        signers.pop();
        totalSigner -= 1;
        
    }

    function mint(address _to, uint256 _amount) public Onlygovernor {
        require(_to != address(0), "0 Address");

        transactions.push(Transaction(_to, _amount,"mint", false));
        uint256 txIndex = transactions.length - 1;
        emit createTx(txIndex, msg.sender, _to, _amount);
        // balances[to] += amount;
        // totalSupply += amount;
    }

    function _mint(address _to, uint256 _amount) internal {

        balances[_to] += _amount;
        totalSupply += _amount;
    }
    
    function burn(uint256 _amount) public Onlygovernor {

        require(msg.sender != address(0), "0 Address");
        
        transactions.push(Transaction(msg.sender, _amount, "burn", false));
        uint256 txIndex = transactions.length - 1;

        emit createTx(txIndex, msg.sender, msg.sender, _amount);

        // totalSupply -= amount;
        // balances[msg.sender] -= amount;
    }


    function _burn(uint256 _amount) internal {
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
    }

    function confirmTransaction(uint256 _txId) external onlySigner txExists(_txId) notConfirmed(_txId) notExecuted(_txId) {
        
        isConfirmed[_txId][msg.sender] = true;
        emit ApproveTx(msg.sender, _txId);
    }

    function getSignerApproval(uint256 _txId) public view txExists(_txId) returns(uint256 count){
        for(uint256 i; i < signers.length; i++){
            if(isConfirmed[_txId][signers[i]]){
                count += 1;
            }
        }
    }

    function executeTransaction(uint256 _txId) external Onlygovernor txExists(_txId) notExecuted(_txId){
        require(getSignerApproval(_txId) >= (signers.length/2) + 1, "Maximum Approval not met!");
        Transaction storage transaction = transactions[_txId];

        if (keccak256(abi.encodePacked('mint')) == keccak256(abi.encodePacked(transaction.name))){
            _mint(transaction.to, transaction.value * 10 ** 18);
        } else if(keccak256(abi.encodePacked('burn')) == keccak256(abi.encodePacked(transaction.name))){
            _burn(transaction.value * 10 ** 18);
        }

        transaction.executed = true;

        emit ExecuteTx(_txId);
    } 

    function revokeConfirmation(uint _txId) external Onlygovernor txExists(_txId) notExecuted(_txId){
        require(isConfirmed[_txId][msg.sender], "Oops!! Transaction not yet confirmed!");
        isConfirmed[_txId][msg.sender] = false;
        emit RevokeTx(msg.sender, _txId);
    }


    function blacklistUser(address _user) public Onlygovernor returns(bool){
        blacklists[_user] = true;
        return true;
    }

    function removeFromBlacklist(address _user) public Onlygovernor{
        blacklists[_user] = false;
    }

}