pragma solidity ^0.8.7;

contract TestEvents {
  uint24 _index;

  event IndexChanged(uint24 indexed index);

  function increaseIndex() public {
    _index += 1;
    emit IndexChanged(_index);
  }

  function decreaseIndex() public {
    require(_index >= 1, "Index already 0");

    _index -= 1;
    emit IndexChanged(_index);
  }

  function index() public view returns (uint24) {
    return _index;
  }
}