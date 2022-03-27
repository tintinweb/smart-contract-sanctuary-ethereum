/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

 
contract ONELOVE {
     
    bytes32 public name = "ONELOVE";
    bytes32 public symbol = "OV";
    uint8 public decimals = 2;
    uint price = 0.1 ether;
    uint256 public initialSupply = 800000000;
    uint256 public totalSupply = initialSupply;
   
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // Constructor function Initializes contract with initial supply tokens to the creator of the contract
function getPrice() public pure returns(uint256) {
     uint256 totalEther = uint256(225800608429140) / uint256(10**18);
     uint256 result = uint256(231481480000000) * 10**18;
     uint256 totalTokens = result / 1 ether;
    //  _totalEther =  totalEther;
     return totalTokens;
 }
 
    //Internal transfer, only can be called by this contract
   
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead

        // Check if the sender has enough
        assert(balanceOf[_from] >= _value);
       
        // Check for overflows//
        assert(balanceOf[_to] + _value > balanceOf[_to]);
       
     
        // Subtract from the sender
        balanceOf[_from] -= _value;
       
        // Add the same to the recipient
        balanceOf[_to] += _value;
   
    }
    function buyTokens(address _receiver) public payable {
    uint256 _amount = msg.value;
    assert (_receiver != address(0)); assert(_amount > 0);
    }
   
    // Transfer tokens
   
    // Transfer tokens from other address

     //* Set allowance for other address
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size + 4) ;
     _;
  }
   
}
// ----------------------------------------------------------------------------