/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
    
}

contract PixSwap {

    address private owner_;

    mapping(bytes32 => bool) usedNonces;

    constructor() {    
        owner_ = msg.sender;
    }

    event PaymentClaimed(address indexed to, uint256 amount, address tokenContract);

    function getEthBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function claimPayment(uint256 amount, bytes32 nonce, bytes memory signature, address tokenContract) public {
    require(!usedNonces[nonce],"nonce already used");
    usedNonces[nonce] = true;
    // this recreates the message that was signed on the client
    bytes32 hash = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, this, tokenContract)));
    require(recover(hash, signature) == owner_ && recover(hash, signature) != 0x0000000000000000000000000000000000000000, "message not signed by owner");
    IERC20 token = IERC20(tokenContract);
    require(getTokenBalance(tokenContract) >= amount,'insufficient token balance');
    require(token.transfer(msg.sender, amount),'transfer failed');
    emit PaymentClaimed(msg.sender, amount, tokenContract);
    }

    function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }


    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function getTokenBalance(address tokenContract) public view returns (uint256) {
        IERC20 token = IERC20(tokenContract);
        return token.balanceOf(address(this));
    }
}