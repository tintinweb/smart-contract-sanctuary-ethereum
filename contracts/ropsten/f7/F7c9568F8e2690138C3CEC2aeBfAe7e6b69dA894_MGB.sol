/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract ECVerify {

    /// signature methods.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, this)));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(hash, v, r, s);
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

contract MGB is ECVerify{
  
    address payable owner;
    address public signer;

    mapping(address => uint) balance;
    mapping (bytes32 => bool) public usedHash;

    event Deposit(address  User, uint256 Amount, uint256 Timestamp);
    event Withdraw(address  User, uint256 Amount, uint256 Timestamp);


    constructor(address _signer) public{
        owner = msg.sender;
        signer = _signer;
    }

  function depositMGB() payable public{
      require(msg.value > 0, "Invalid amount");
      balance[address(this)] += msg.value;
      emit Deposit(msg.sender, msg.value, block.timestamp);
  } 

//   function Withdraw(uint256 amount) payable public{
//       require(msg.sender == owner, "Only owner");
//       require(balance[address(this)] > amount, "Invalid amount");
//       balance[address(this)] -= amount;
//       owner.transfer(amount);
//   }

  function withdraw(uint256 _amount, uint8 _nonce, bytes memory signature) external {
        bytes32 hash = keccak256(
            abi.encodePacked(
                toString(address(this)),
                toString(msg.sender),
                _amount,
                _nonce
            )
        );
        
        require(!usedHash[hash], "Invalid Hash");
        
        require(recoverSigner(hash, signature) == signer, "Signature Failed");
        
        usedHash[hash] = true;
        
        require(msg.sender.send(address(this).balance));

        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

 
  function contractBalance() public view returns(uint){
      return balance[address(this)];
  }
   
}