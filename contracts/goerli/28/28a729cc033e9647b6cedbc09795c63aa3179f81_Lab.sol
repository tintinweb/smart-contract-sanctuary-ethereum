//SPD-Licenced: UNLICENSED
pragma solidity 0.8.17;

contract Lab {

  uint public varr = 666;
  uint[] public array1;

  function alert(uint256 xxx) public view returns(uint) {
      return 777;
  }

  function pusher() public {
      array1.push(1);
  }

   function pusher(uint i) public {
      array1.push(i);
  }

}