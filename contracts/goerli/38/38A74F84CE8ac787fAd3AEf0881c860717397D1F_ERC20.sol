//SPDX-License-Identifier:MIT

pragma solidity ^0.8.6;

contract ERC20{
    mapping(address=>uint) balanceOf;
    mapping(address=>mapping(address=>uint)) allowance;
    uint tokenInCirculation;
    address owner;
    string version;
    string _name;
    string _symbol;
    string _version;
    

    function name() public view returns(string memory){
       return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function decimals() public pure returns(uint8){
        return 18;
    }

    function initialization(string memory _Name,string memory _Symbol,string memory _Version,address deployer, uint amount)public{
        _name=_Name;
        _symbol=_Symbol;
        _version=_Version;
        tokenInCirculation+=amount;
        unchecked{
            balanceOf[deployer]+=amount;
        }
    }

    function transfer(address to , uint amount)public returns(bool){
        require(to != address(0), "ERC20: transfer to the zero address");
        uint senderBalance=balanceOf[msg.sender];
        require(senderBalance >= amount,"Insufficient Balance");
        unchecked{
            balanceOf[msg.sender]-=amount;
            balanceOf[to]+=amount;

        }
        
        return true;
    }

    function getTotalSupply() public view returns(uint){
        return tokenInCirculation;
    }

    function getBalanceOf(address user) public view returns(uint){
        return balanceOf[user];
    }


    function getVersion() view public returns(string memory ){
        return _version;
    }


}