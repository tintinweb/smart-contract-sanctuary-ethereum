/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract ERC20_Standard {

    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);

    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}

contract Owership {

    address public contractOwner;
    address public newOwner;

    event TransferOwnership(address indexed _from, address indexed _to);

    constructor() {
        contractOwner = msg.sender;
    }

    function changeOwner(address _to) public {
        require(msg.sender == contractOwner, "Only owner of the contract can execute it");
        newOwner = _to;
    }

    function acceptOwner() public {
        require(msg.sender == newOwner, "Only new assigned owner can call it");
        emit TransferOwnership(contractOwner, newOwner);
        contractOwner = newOwner;
        newOwner = address(0);     // ya jo phly newOwner ka address tha us ko zero kr dyta ha.
    }

}


contract MyERC20 is ERC20_Standard,Owership {

    string public _name;
    string public _symbol;
    uint8 public _decimal;
    uint public _totalSupply;

    address public _minter;

    mapping(address => uint)  tokenBalances;

    mapping(address => mapping(address => uint))  allowed;


    constructor(address minter_) {
        _name = "Token";
        _symbol = "TKN";
        _totalSupply = 1000 * 10**18;
        _decimal = 18;
        _minter = minter_;

        tokenBalances[_minter] = _totalSupply;
    }


    function name() public view override returns (string memory){
        return _name;
    }

    function symbol() public view override returns (string memory){
        return _symbol;
    }

    function decimals() public view override returns (uint8){
        return _decimal;
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance){
        return tokenBalances[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(tokenBalances[msg.sender] >= _value, "Insufficent balance");
        tokenBalances[msg.sender] -= _value;
        tokenBalances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        uint allowedBal = allowed[_from][msg.sender];      // _from minter ka address ha jaha token parhy ha aur msg.sender user ka address ha jo depolyer ha. Matlab ya ky msg.sender vo amount of token access kry ga jo minter ny us ko allow keya ha.
        require(allowedBal >= _value, "Insufficant Balance");        // allowedBal ek variable declared keya ha jis ma msg.sender(user) ko ktny token ka access deya ha minter na us ki value ko store kr lyta ha allowedBal ky variable ma. Phir chech krta ha allowedBal ma jo value ha vo input _value sy big ha. Aghar big ha to us ko execute kr dyta ha.
        tokenBalances[_from] -= _value;
        tokenBalances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true; 
    }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        require(tokenBalances[msg.sender] >= _value, "Insufficant Token");
        allowed[msg.sender][_spender] = _value;        // msg.sender ky pas 21000000 token ha. msg.sender ny spender ko ktny token ka access dena ha. For example:- 100 token ka access deta ha is ko, is ka matlab ya transfer krty waqat har bar 100 token ko transfer kr skty ho minter sy user ky account ma. Matlab ek bar 100 token transfer keyay dusray bar bi 100 token kr skty ho.
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
        return allowed[_owner][_spender];              // msg.sender(owner) ny spender ko ktny token ka access deya ha. Ya function sirf ya chech krta ha.
    }

}