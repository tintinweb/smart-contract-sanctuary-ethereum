/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

contract ERC20 {
    function transfer(address to, uint256 amount) external  returns (bool){}
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool){}
    function approve(address spender, uint256 amount) public virtual returns (bool){}
    function balanceOf(address account) public view virtual returns (uint256){}
}
contract Pool {
    function addToken(ERC20 token, uint256 amount) public {}
}

contract RefWine {
    ERC20 public token;
    Pool public pool;
    uint256 public _buyerToRef;
    constructor(ERC20 _token, Pool _pool){
        token = _token;
        pool = _pool;
        token.approve(address(pool), 10**12*10**18);
    }

    // claves de referidos
    mapping(uint256 => address) private ref;
    mapping(address => uint256) private refOf;
    mapping(address => uint256) private balance;


    // guardar los token a la pool de los admin
    function addToPool(uint amount) internal {
        pool.addToken(token, amount);
    }

    function refNumber() internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(msg.sender,block.timestamp,_buyerToRef)))%10**9;
    }

    function sendToken(uint256 _ref) internal {
        uint256 amount = 4*10**18;
        require(token.balanceOf(msg.sender)>=amount);
        token.transferFrom(msg.sender,address(this),amount);
        if(ref[_ref]==address(0)){
            balance[address(pool)] += amount-10**18;
            addToPool(10**18);
        }else{
            balance[ref[_ref]] += amount-10**18;
            token.transfer(ref[_ref],amount);
        }
    }

    function buy(uint256 _ref) public {
        sendToken(_ref);

        uint256 newRef = refNumber();
        ref[newRef] = msg.sender;
        refOf[msg.sender] = newRef; 
    }

    //retirar fondos
    function withdraw(uint256 amount) public {
        //evalua si tiene saldo para continuar
        require(balance[msg.sender] >= amount, "no tiene suficiente fondos para retirar");
        // resta el saldo a retirar
        balance[msg.sender] -= amount;
        // pregunta si el que retira es la pool, y ejecuta el retiro adecuado por ser un contrato
        if(msg.sender == address(pool)){
            addToPool(amount);
        }else{
            token.transfer(msg.sender,amount);
        }
    }

    //ver mapping 
    function accountOfRef(uint256 _ref) public view returns(address){
        return ref[_ref];
    }
    function refOfAccount(address account) public view returns(uint256){
        return refOf[account];
    }
    function balanceOf(address account) public view returns(uint256){
        return balance[account];
    }
}