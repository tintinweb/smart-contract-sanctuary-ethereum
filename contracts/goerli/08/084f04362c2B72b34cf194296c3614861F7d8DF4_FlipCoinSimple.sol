// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*
   ______  ______               ______     ______  
 .' ___  ||_   _ `.           .' ____ \  .' ___  | 
/ .'   \_|  | | `. \  ______  | (___ \_|/ .'   \_| 
| |         | |  | | |______|  _.____`. | |        
\ `.___.'\ _| |_.' /          | \____) |\ `.___.'\ 
 `.____ .'|______.'            \______.' `.____ .' 
   ChubiDuracell                 smart contract
*/

// !!!!!!!!!!!!!!!!!!!!!   TEMP  !!!!!!!!!!!!!!!!!!!!!


contract FlipCoinSimple{

    event Flip(address who, uint when, bool didWin, bool headCoin);

    mapping(address => uint) public userBank;


    address owner;

    IERC20 public token;


// There are few solution how to play with ERC20 tokens;
// 1. Straight > Front 2 tx (approve  then flip)
// 2. Make a valut in this sc, and then user can sign just 1 tx, and after he can withdraw the rest
// SIMPLE = play with ETH

    function flip(bool _guess, uint _bet) external {
        require(userBank[msg.sender] >= _bet, "Hey, you broke! lol");

        uint randomNum = _pseudoRandom(uint(uint160(msg.sender)));
        bool won;

    //   HEAD => TRUE & Even
        if((randomNum % 2 == 0) == _guess){
            token.transfer(msg.sender, _bet * 2);
            userBank[msg.sender] -= _bet;
            won = true;
        } 

        emit Flip(msg.sender, block.timestamp, won, randomNum % 2 == 0);
    }

// POOL
// player send tokens to this sc => 2 tx from Front (approve then transfer) => set up bet from front => starts playing => withdraw if player doesn want to continue
    function popupAcc(uint _funds) external {
        require(_funds >= getBalance(), "Unfortunately we are out of tokens here");
        // APPROVE FIRST
        token.transferFrom(msg.sender, address(this), _funds);
        userBank[msg.sender] += _funds;
    }

    function withdrawPlayer()external{
        require(userBank[msg.sender] > 0, "Are u scamer? You aint have shit here!");
        userBank[msg.sender] = 0;
        token.transfer(msg.sender, checkUrBalance());
    }

    function checkUrBalance() public view returns(uint){
        return userBank[msg.sender];
    }

/////////////////////////////// DEV FUNC \\\\\\\\\\\\\\\\\\\\\\\\\\\
    modifier onlyOwner(){
      require(msg.sender == owner, "You are not an owner!");
      _;
    }

    constructor(IERC20 _token){
      owner = msg.sender;
      token = _token;
    } 

    function withdrawOwber()external onlyOwner{
        token.transfer(owner, address(this).balance); // unfair func
    }

    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function _pseudoRandom(uint _salt) private view returns(uint256 randomNum) {
      uint256 num = uint256(keccak256(abi.encodePacked(
        _salt,
        tx.origin, 
         blockhash(block.number - 1), 
        block.timestamp)));

      return num;
    }
}


interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}