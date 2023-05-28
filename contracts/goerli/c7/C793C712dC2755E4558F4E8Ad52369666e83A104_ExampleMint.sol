/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

pragma solidity 0.8.13;

contract ExampleMint {

    uint256 public constant MAX_SUPPLY = 10000;
    address[MAX_SUPPLY] _owners;
    uint256 public constant PRICE = 0.0001 ether;
    uint256 private index = 1;
    
    event TransferSingle(address, address, address, uint256, uint256);

    function mint_efficient_1268F998() external payable {
        require(msg.value == PRICE, "wrong price");
        uint256 _index = index;
        require(_index < MAX_SUPPLY, "supply limit");

        emit TransferSingle(msg.sender, address(0), msg.sender, _index, 1);
        assembly {
            sstore(add(_owners.slot, _index), caller())
        }

        unchecked {
            _index++;
        }
        index = _index;
    }
}