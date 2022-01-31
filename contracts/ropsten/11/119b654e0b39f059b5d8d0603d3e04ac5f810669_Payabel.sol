/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.8.7;

contract Payabel{
    struct URL{
        string name;
        string[] onions;
    }
    mapping(address=>URL[]) public URLsByOwner;
    mapping(string=>string[]) public nameOnions;
    mapping(string => bool) public nameExist;
    address payable public owner;
    constructor()payable{
        owner = payable(msg.sender);
    }
    event Deposit(address sender, uint amount, uint balance);
    mapping(address=>uint) public userBalance;
    uint public totalSupply;
    event LogDepositReceived(address sender);
    function deposit() payable external {
        userBalance[msg.sender]+=msg.value;
        totalSupply += msg.value;
        assert(address(this).balance >= totalSupply);
        emit Deposit(msg.sender, msg.value, userBalance[msg.sender]);
    }
    fallback() external payable {
       require(msg.data.length == 0); 
       emit LogDepositReceived(msg.sender);
    }
    event userWithDraw( address user,uint amount, uint balance);
    function userWithdraw(uint _amount) public payable {
        require(userBalance[msg.sender]>=_amount);
        userBalance[msg.sender]-=_amount;
        totalSupply -= _amount;
        payable(msg.sender).transfer(_amount);
        emit userWithDraw( msg.sender, _amount, userBalance[msg.sender]);
    }
    function getBalance()external view returns(uint){
        return address(this).balance;
    }
    function setURL(string memory _urlName)external{
        require(userBalance[msg.sender]>=3000);
        require(!nameExist[_urlName]);
        require(owner.send(3000));
        userBalance[msg.sender]-=3000;
        totalSupply -= 3000;
        URL memory newURL;
        newURL.name=_urlName;
        URLsByOwner[msg.sender].push(newURL);
        nameExist[_urlName] = true;
    }
    function setOnions( string memory _urlName, string[] memory _onions)external{
        require(userBalance[msg.sender]>=3000);
        require(nameExist[_urlName]);
        URL[] memory urls = URLsByOwner[msg.sender];
        for(uint i=0; i<urls.length; i++){
            if(memcmp(bytes(urls[i].name), bytes(_urlName))){
                require(userBalance[msg.sender]>=3000);
                require(owner.send(3000));
                userBalance[msg.sender]-=3000;
                totalSupply -= 3000;
                urls[i].onions=_onions;
                nameOnions[urls[i].name]=_onions;
            }
        }
    }
    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    function getOnions(string memory _urlName)external view returns(string[] memory){
        string[] memory onions = nameOnions[_urlName];
        return onions;
    }
}