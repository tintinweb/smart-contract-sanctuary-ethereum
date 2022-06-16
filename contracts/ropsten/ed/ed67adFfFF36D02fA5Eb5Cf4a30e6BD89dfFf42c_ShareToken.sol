pragma solidity ^0.4.0;

import "./Owner.sol";

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ShareToken is Owner,ERC20Interface{
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event CreatPocket(address indexed from,uint amount,uint time,uint pocketIndex);
    event JoinPocket(address indexed from,uint pocketIndex);
    event OpenPocket(uint pocketIndex,uint[] pocketResult);

    constructor() public{
        symbol = "ST";
        name = "ShareToken";
        decimals = 18;
        _totalSupply = 1 * 10 ** uint256(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0),owner,_totalSupply);
    }

    struct Pocket{
        uint amount;
        uint maxPeople;
        uint endTime;
        uint count;
        bool end;
        address[] addressList;
    }

    mapping(uint => Pocket) public pocketMap;
    uint pocketCount;
    uint public chargeBalance;

    function cteatePocket(uint amount,uint maxPeople,uint time) public returns(bool success){
        require(amount>=1000);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        address[] memory addressList = new address[](maxPeople);
        addressList[0] = msg.sender;
        Pocket memory pocket = Pocket(amount,maxPeople,now + time,1,false,addressList);
        pocketMap[pocketCount] = pocket;
        pocketCount ++;
        emit CreatPocket(msg.sender,amount,time,pocketCount-1);
        return true;
    }

    function joinPocket(uint index) pocketCanJoin(index) public returns(bool success) {
        balances[msg.sender] = balances[msg.sender].sub(pocketMap[index].amount);
        pocketMap[index].addressList[pocketMap[index].count] = msg.sender;
        pocketMap[index].count += 1;
        emit JoinPocket(msg.sender,index);
        return true;
    }

    function checkPocketEnd() isOwner public view returns(bool){
        for(uint i = 0 ; i < pocketCount ; i ++){
            if(!pocketMap[i].end && now > pocketMap[i].endTime)return true;
        }
        return false;
    }

    function openPocket() isOwner public returns(bool){
        for(uint i = 0 ; i < pocketCount ; i ++){
            openOnePocket(i,pocketMap[i]);
        }
        return true;
    }

    function openOnePocket(uint i,Pocket storage pocketOne) internal{
        if(!pocketOne.end && now > pocketOne.endTime){
            address[] memory addressList = pocketOne.addressList;
            uint joinCount = pocketOne.count;
            uint amount = pocketOne.amount;
            uint total = joinCount.mul(amount);
            uint charge = total * 2 / 100;
            chargeBalanceAdd(charge);
            uint pocketAmount = total - charge;
            uint256[] memory randomArray = new uint256[](joinCount); 
            uint randomCount;
            for(uint m = 0 ; m < joinCount ; m ++){
                randomArray[m] = uint(keccak256(abi.encodePacked(now, msg.sender, m))) % 100;
                randomCount += randomArray[m];
            }
            uint256[] memory pocketResult = new uint256[](joinCount);
            amount = 0;
            for(uint n = 0 ; n < joinCount-1 ; n ++){
                pocketResult[n] = randomArray[n]*pocketAmount.div(randomCount);
                amount += pocketResult[n];
            }
            pocketResult[joinCount-1] = pocketAmount - amount;
            for(uint x = 0 ; x < joinCount ; x ++){
                address a = addressList[x];
                balances[a] = balances[a].add(pocketResult[x]);
            }
            pocketOne.end = true;
            emit OpenPocket(i,pocketResult);
        }
    }

    modifier pocketCanJoin(uint index){
        require(pocketMap[index].amount != 0 &&  now < pocketMap[index].endTime && pocketMap[index].count < pocketMap[index].maxPeople);
        _;
    }

    function chargeBalanceAdd(uint amount) internal{
        chargeBalance = chargeBalance.add(amount);
    }

    function totalSupply() public constant returns (uint){
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public constant returns (uint){
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining){
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint tokens) public returns (bool success){
        return transferTo(msg.sender,to,tokens);
    }

    function transferTo(address from,address to, uint tokens) public returns (bool success){
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        balances[from] = balances[from].sub(tokens);
        allowed[from][to] = allowed[from][to].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }

    function exchangeST() public payable returns (bool){
        require(msg.sender != owner);
        uint value = msg.value;
        transferTo(owner,msg.sender,value);
        owner.transfer(value);
        return true;
    }

}