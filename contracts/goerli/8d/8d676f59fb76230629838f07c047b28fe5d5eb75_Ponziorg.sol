// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./ownable.sol";

contract Ponziorg is Ownable {
    //track who owns the positions in the pyramid,owned by address(0) will mean empty
    mapping (uint => address) public ownerOfLeaves;
    uint layerToFill = 0; //layer 0 has 1 slots, layer 1 has 2 slot, layer 2 4, layer 3 8, layer 4,16
    uint basePrice = 0.0011 ether ;
    uint positionToFill=0;//slots are numbered 0 to positionToFill at any moment
    uint emptySlots =0; 

    event newdisciple(uint position, address indexed newdisciple);
    //we need to avoid people entering and exiting simultaneously to force the pyramid to expand emptily, maybe add a cost ?
    function withdrawAll() external onlyOwner {
    address payable _owner = payable(owner());
    _owner.transfer(address(this).balance);
  }
    function currentEntryPrice() public view returns(uint) {
        return basePrice * (3 + layerToFill);
        //we might need to modify if we want the base layer to be wider or if we change the parameters of new layers

    }
    function enterThePyramid(uint _layermax, address _addressEntering) payable external {
        require(layerToFill <= _layermax); //in case of slippage between sending and current
        uint priceNow = currentEntryPrice();
        require(msg.value >= priceNow); //need to send enough eth to enter the pyramid
        ownerOfLeaves[positionToFill]=_addressEntering;
        positionToFill++; //update the owner
        if (positionToFill==2**(layerToFill+1) -1) {
            layerToFill++;
        } //update layer in case we reach the end of a layer
        address payable _sender = payable(_msgSender());
        _sender.transfer(msg.value - priceNow);
    }
    // As we exit all positions have same value (better for initial participants ofc)
    function exitThePyramid(uint[] memory _positions) external {
        uint amount=_positions.length;
        for (uint i = 0; i < amount; i++) {
            require(ownerOfLeaves[_positions[i]] == _msgSender());
            ownerOfLeaves[_positions[i]]=address(0);           
        }
        address payable _sender = payable(_msgSender());
        _sender.transfer(uint(amount * (address(this).balance / (positionToFill - emptySlots)))); //share of the exiter, could be not all leaves !
        emptySlots=emptySlots+_positions.length;        
    }
    function getPowerOfAddress(address _address) public view returns(uint) {
    uint power;
    for (uint i = 0; i < positionToFill; i++) {
      if (ownerOfLeaves[i] == _address) {
        power++;
      }
    }
    return power;
    }
    function getSlotsOfAddress(address _address) public view returns(uint[] memory) {
        uint[] memory result = new uint[](getPowerOfAddress(_address));
        uint counter;
    for (uint i = 0; i < positionToFill; i++) {
      if (ownerOfLeaves[i] == _address) {
        result[counter]=i;
        counter++;
      }
    }
    return result;
    }

}