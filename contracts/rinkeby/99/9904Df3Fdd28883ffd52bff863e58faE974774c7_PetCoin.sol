/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity ^0.5.16;


contract PetCoin{
    struct  Dog{
        string id;

        string name;

        string age;

        string img;

        uint price;

        string status;

        string createTime;
    }

    string  name;

    string  symbol;

    uint decimals;

    Dog[] public dogs;

    address public minter;

    uint public totalSupply;

    mapping(address=>Dog) public userDog;

    mapping(address=>uint) public balances;

    mapping(address=>bool) public blackList;

    mapping(address=>bool) public whiteList;

    event Transfer(address from,address to,uint value);

    event AddBlackList(address to,bool b);

    event RemoveBlackList(address to,bool b);

    constructor(string memory name_,string  memory symbol_,uint decimals_,uint totalSupply_)public{
        name=name_;
        symbol=symbol_;
        decimals=decimals_;
        totalSupply=totalSupply_;
        balances[msg.sender]=totalSupply_;
        minter=msg.sender;
    }

    function addDog(string memory _id,string memory _dogName,string memory _age,string memory _img,uint _price,string memory _status,string memory _createTime) public returns(bool res){
        dogs.push(Dog(_id,_dogName,_age,_img,_price,_status,_createTime));
        return true;
    }

    function bugDog(uint index) public returns(bool){
        userDog[msg.sender]=dogs[index];
        send(minter,dogs[index].price);
        delete dogs[index];
        return true;
    }


    function send(address to,uint value) public returns(bool){
        require(!blackList[msg.sender]&&!blackList[to],"ERC20: transfer fail...");
        require(balances[msg.sender]>=value,"ERC20: transfer fail...");
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require((balances[to]+value)>=value,"ERC20: transfer fail....");
        uint sender= balances[msg.sender];
        uint getter=balances[to];
        uint total=sender+getter;
        balances[msg.sender]-=value;
        balances[to]+=value;
        require((balances[to]+balances[msg.sender])==total,"ERC20: transfer fail.....");
        emit Transfer(msg.sender,to,value);
        return true;
    }

    function addBlackList(address to) public returns(bool res){
        require(msg.sender==minter,"ERC20: addBlackList fail...");
        blackList[to]=true;
        emit AddBlackList(to,true);
        return true;
    }

    function removeBlackList(address to) public returns(bool res){
        require(msg.sender==minter,"ERC20: addBlackList fail...");
        blackList[to]=false;
        emit RemoveBlackList(to,false);
        return true;
    }
    

}