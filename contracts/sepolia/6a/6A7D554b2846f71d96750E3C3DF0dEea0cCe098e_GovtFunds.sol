// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract GovtFunds {
   struct scheme {
    address owner;
    string title;
    string description;
    uint256 target;
    uint256 deadline;
    uint256 totalamount;
    string image;
    address[] central;
    uint256[] donations;
    // donator.central donations state
   }
   mapping (uint256 => scheme) public schemes;

   uint256 public numberofschemes = 0;

   function requestfund(address _owner, string memory _title, string memory _description, uint256 _target, 
   uint256 _deadline, string memory _image) public returns (uint256) { 
        scheme storage scheme = schemes[numberofschemes];

        require(scheme.deadline < block.timestamp, "the deadline should be in future");

        scheme.owner = _owner;
        scheme.title = _title;
        scheme.description = _description;
        scheme.target = _target;
        scheme.deadline = _deadline;
        scheme.totalamount =  0;
        scheme.image = _image;

        numberofschemes++;

        return numberofschemes - 1;

   }

   function allocatefunds(uint256 _id) public payable {
        uint256 amount = msg.value;

        scheme storage scheme = schemes[_id];

        scheme.central.push(msg.sender);
        scheme.donations.push(amount);
        
        (bool sent, ) = payable(scheme.owner).call{value: amount}("");

        if(sent) {
            scheme.totalamount = scheme.totalamount + amount;
        }
   }

   function trackfunds(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return (schemes[_id].central, schemes[_id].donations);
   }

   function getschemes() public view returns (scheme[] memory) {
        scheme[] memory allschemes = new scheme[](numberofschemes);

        for (uint i=0;i<numberofschemes; i++) {
            scheme storage item = schemes[i];

            allschemes[i] = item;
        }

        return allschemes;
   }

}