/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity >=0.8.7;
contract Character{

    address public owner;
    string public name_char;
    string public race;
    string public class;
    uint8 public health;
    function SetHealth(uint8 _damage)virtual external
    {
        if(_damage >= health)
        {
            health = 0;
        }
        else if(_damage < health)
        {
            health = health - _damage;
        }
    }

}
contract Weapons
{
    string public name_w;
    uint8 public attack = 10;
}

contract Player is Character, Weapons
{
    string public constant currency = "gold";
    string public constant symbol = "g";
    uint8 public constant decimal = 4;
    uint8 public level;
    uint8 public points;
    uint public constant price_p = 3;
    uint public constant price_l = 100;
    uint totalSupply = 0;
    mapping(address => uint) pouch;
    constructor(string memory _name, string memory _race, string memory _class, string memory _name_w )
    {
        owner = msg.sender;
        name_char = _name;
        race = _race;
        class = _class;
        name_w = _name_w;
        health = 100;
        level = 1;
        points = 0;
        

    }
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    modifier havePoints(){
        require(points >0);
        _;
    }
    function SetHealth(uint8 _damage)external override{
        if (_damage>health)
        {
            health = 0;
        }
        else health -=_damage;
    }
    function attack_p(address _playerAdd)public onlyOwner{
        require(health > 0, "You are dead");
        require(Player(_playerAdd).health() > 0, "The player is dead");

        Player player = Player(_playerAdd);
        player.SetHealth(attack);
        if(player.health()==0)
        {
            level +=1;
            points +=5;
            
        }
    }
    function cure()public onlyOwner havePoints{
        health +=5;
        points -=1;
    }
    function improveAttack()public onlyOwner havePoints
    {
        attack +=1;
        points -=1;
    }
    function mint(address _adr, uint _c)public
    {
        require(msg.sender == owner);
        totalSupply +=_c;
        pouch[_adr] += _c;
    }

    function balanceOf()public view returns(uint)
    {
        return pouch[msg.sender];
    }

    function balanceOf(address _adr)public view returns(uint)
    {
        return pouch[_adr];
    }

    function transfer(address _adn, uint _val)public
    {
        require(pouch[msg.sender]>=_val);
        pouch[msg.sender] -=_val;
        pouch[_adn] += _val;
    }
    function transferFrom(address _from, address _to, uint _val)public
    {
        require(pouch[_from]>= _val);
        pouch[_from] -=_val;
        pouch[_to] += _val;
    }
    function Buy_points(address _adn)public
    {
        require(pouch[msg.sender]>=price_p);
        pouch[msg.sender]-=price_p;
        points +=1;
            
    }
    function Buy_levels(address _adn)public
    {
        require(pouch[msg.sender]>=price_l);
        pouch[msg.sender]-=price_l;
        level +=1;
            
    }
    
}