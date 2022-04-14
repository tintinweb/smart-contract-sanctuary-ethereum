contract Test {
  address owner;
  constructor(address _owner) {
    owner = _owner;
  }

  function setOwner(address payable _owner) public {
    owner = _owner;
  }


  function getOwner() public view returns(address) {
    return owner;
  }

}