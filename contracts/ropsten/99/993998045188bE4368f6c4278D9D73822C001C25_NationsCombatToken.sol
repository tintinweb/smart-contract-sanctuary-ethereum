//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";

// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// The Cryptos Token Contract
contract NationsCombatToken is ERC20Interface , Ownable{
    string public name = "Nations Combat";
    string public symbol = "NCTTB";
    uint256 public decimals = 18;
    uint256 public override totalSupply;

    address public founder;
    mapping(address => uint256) public balances;
    // balances[0x1111...] = 100;

    mapping(address => mapping(address => uint256)) allowed;

    // allowed[0x111][0x222] = 100;

    constructor() {
        totalSupply = 50000000*10**18;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        virtual
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);

        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual override returns (bool success) {
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;

        return true;
    }
}

contract NationsCombatICO is NationsCombatToken {
    address public admin;
    address payable public deposit;
    uint256 tokenPrice; 
        
  
    uint256 public raisedAmount; 
    uint256 private saleStart;
    uint256 private saleEnd; 
    ERC20Interface public tokenContract;
    uint256 private tokenTradeStart; 
    uint256 public maxInvestment = 25000*10**18 ;
    uint256 public minInvestment = 500*10**18;

    enum State {
        beforeStart,
        running,
        afterEnd,
        halted
    } 
    State public icoState;

    constructor(address payable _deposit, address tokenAddress) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
        tokenContract = ERC20Interface(tokenAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function changeStartTime(uint _time) public onlyAdmin{
        require(_time >= block.timestamp);
        saleStart = _time;
        icoState = State.running;
    }

    function changeEndTime(uint _endtime) public onlyAdmin{
        uint endtime = saleStart + _endtime;
        require(endtime > saleStart);
        saleEnd = endtime;
    }

    function changeTokeTardeTime(uint _tradetime) public onlyAdmin{
        uint tradetime = saleEnd + _tradetime;
        require(tradetime > saleEnd);
        tokenTradeStart = tradetime;
    }

    function resume() public onlyAdmin {
        icoState = State.running;
    }

        function halted() public onlyAdmin {
        icoState = State.halted;
    }

    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }

    function getCurrentState() public view returns (State) {
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < saleStart) {
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }
function multiply(uint x, uint y) internal pure returns (uint z) {
require(y == 0 || (z = x * y) / y == x);
}
    event Invest(address investor, uint256 value, uint256 tokens);

function setPrice(uint256 _tokenPrice)public onlyOwner {
    tokenPrice = _tokenPrice;

}
function getPrice(uint256 token) public view returns(uint256){
    return multiply(token, tokenPrice);
}
    function buytoken(uint256 token) public payable returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running ,"State is not running");
        require(msg.value == multiply(token, tokenPrice),"eth sent is not enough");
        require(token*10**18 >= minInvestment && token*10**18 <= maxInvestment,"Max or Min investment Exceeded");
        require(tokenContract.balanceOf(address(this))>= token*10**18,"No more token in the contract!");
        require(tokenContract.transfer(msg.sender, token*10**18));

        

        raisedAmount += msg.value;

        // adding tokens to the inverstor's balance from the founder's balance
        balances[msg.sender] += token;
        balances[founder] -= token;
        deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address

        emit Invest(msg.sender, msg.value, token);

        return true;
    }
  

    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(block.timestamp > tokenTradeStart); 

        super.transfer(to, tokens);
        return true;
    }

    function endSale() public onlyAdmin {
        require(msg.sender == admin);
        require(
            tokenContract.transfer(
                admin,
                tokenContract.balanceOf(address(this))
            )
        );

        payable(admin).transfer(address(this).balance);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart); 

        NationsCombatToken.transferFrom(from, to, tokens); 
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}