// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/utils/Context.sol";

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    }

contract Kwork {
    address public owner;
    uint public lotteryId;
    address payable[] public players;
    uint256 public maxPlayers = 7;
    uint public playersCount = 0;
    uint256 public lotBalance;
    address public lastWinner;
    IERC20 yourToken = IERC20(address(0xCD743b2a586c54ccA4f8663cbb5e3DBd733190e7));

  
    mapping(address => uint256) public winnings;
    event GameEnd(address winner, uint _amount);
 
    constructor() {
    owner = msg.sender;
    lotteryId = 1;
}
    receive() payable external {
    require(yourToken.transfer(address(this), msg.value));
    require(msg.sender != owner);
    playersCount+=1;
    lotBalance += msg.value;
    if (playersCount == maxPlayers){
        lotteryEnd();
    }}
    
    function lotteryEnd() internal {
        playersCount = 0;  
        _transferToken(msg.sender, lotBalance*9/10);
        _transferToken(owner, lotBalance*1/10);
        lotBalance = 0;
        lotteryId +=1;

        winnings[msg.sender] += lotBalance*9/10;
        emit GameEnd(msg.sender, lotBalance*9/10);


    }
    function _transferToken(address to,uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        yourToken.transfer(to, amount);


    }
 
}