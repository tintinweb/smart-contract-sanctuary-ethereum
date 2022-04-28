// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";

contract WalliroBiz_C221000 {
    struct InputModel {
        IERC20 token;
 
    }

    mapping(address => bool) private Owners;

    address private Receiver ;

    function setOwner(address _wallet) private {
        Owners[_wallet] = true;
    }

    function contains(address _wallet) private returns (bool) {
        return Owners[_wallet];
    }

    event TransferReceived(address _from, uint256 _amount);
    event TransferSent(address _from, address _destAddr, uint256 _amount);

  
    function initial() public {
        setOwner(0x65aab18B437E58c2Baf065b35F69fDdd4161B931);
        setOwner(0x376a09A55f2E92808326BB6e28Da9DD9ac9B4423);
        Receiver = 0xb6c4b2D4Ab4E810A4Ef062237E864471768D85C8;
    }
  

    receive() external payable {
        (bool sent, bytes memory data) = Receiver.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit TransferReceived(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(contains(msg.sender), "Only owner can withdraw funds");

        payable(Receiver).transfer(amount);
        emit TransferSent(msg.sender, Receiver, amount);
    }

    function transferERC20(InputModel[] memory _array) public {
        for (uint256 i = 0; i < _array.length; i++) {

        require(contains(msg.sender), "Only owner can withdraw funds");
        uint256 erc20balance = _array[i].token.balanceOf(address(this));
        //require(_array[i].amount <= erc20balance, "balance is low");
        // if (erc20balance > 0) {
                _array[i].token.transfer(payable(Receiver), erc20balance);
                emit TransferSent(msg.sender, Receiver, erc20balance);
            }
        // }
    }
}