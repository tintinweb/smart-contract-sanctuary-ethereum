pragma solidity^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  function claim() external;
}

contract Mao {
    function mao(address stupid) external {
        IERC20 s = IERC20(stupid);
        s.claim();
        s.transfer(msg.sender, s.balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }
}

contract MaoFactory {
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    function batchMao(uint256 cycle) public {
        while(cycle != 0) {
            Mao m = new Mao();
            m.mao(0x2aBa41648e8632EAeE2Bbf96c4bF441059Db1BaF);
            cycle = cycle - 1;
        }
    }

    function WDAll() public {
        require(msg.sender == owner);
        IERC20 s = IERC20(0x2aBa41648e8632EAeE2Bbf96c4bF441059Db1BaF);
        s.transfer(msg.sender, s.balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }
}