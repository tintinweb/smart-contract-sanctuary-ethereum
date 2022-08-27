// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Partial {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @title Minimal contract able to airdrop tokens once approval is given
///        heavily inspiried by: https://nft.life/batch-transfer 
/// @author 🍖
contract BatchTransfer {
  /// @notice                 transfers each token in '_tokens' to each address in '_to' from the msg.sender 
  /// @dev                    the order of '_to' and '_tokens' is very specific because it dictates which token goes to who 
  ///                         the tokens also drop in a reverse linear pattern from last on the list to the first
  /// @param  _tokenContract  which token contract you would like to use
  /// @param  _to             list of addresses to which you'd like to drop tokens token
  /// @param  _tokens          list of token ids you'd like to drop to each respective address in _to
  function batchTransfer(IERC721Partial _tokenContract, address[] calldata _to, uint256[] calldata _tokens) external {
    uint256 length = _to.length;
    while (length > 0) {
      unchecked { --length; }
      _tokenContract.transferFrom(msg.sender, _to[length], _tokens[length]);
    }
  }
}