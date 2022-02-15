pragma solidity 0.7.6;

import './PixelPavel.sol';

interface ISetup {
  event Deployed(address instance);
  function isSolved() external view returns (bool);
}

contract Setup is ISetup {
  PixelPavel public instance;

  constructor() payable {
    require(msg.value == 298, "Gotta pay to play, 298 Wei.");
    instance = new PixelPavel{value: 298 wei}();
    emit Deployed(address(instance));
  }
  
  function isSolved() override external view returns (bool) {
    return (address(instance).balance == 0);
  }
}