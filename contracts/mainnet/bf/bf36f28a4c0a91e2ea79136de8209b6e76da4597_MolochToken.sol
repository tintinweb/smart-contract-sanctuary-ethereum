/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

}

interface IMOLOCH { 
    function totalShares() external view returns (uint256);
    function totalLoot() external view returns (uint256);
    function memberAddressByDelegateKey(address user) external view returns (address);
    function members(address user) external view returns (address, uint256, uint256, bool, uint256, uint256);
}

contract MolochToken {
    IMOLOCH public moloch;
    string public name;
    string public symbol;
    uint256 public constant decimals = 18;

    function setUp(address _moloch, string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        moloch = IMOLOCH(_moloch);
    }
    
    function totalSupply() public view returns (uint256) {
        return (moloch.totalShares() + moloch.totalLoot()) * (10 ** decimals);
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 shares;
        uint256 loot;
        address memberAddress = moloch.memberAddressByDelegateKey(account);
        (,shares,loot,,,) = moloch.members(memberAddress);
        
        return (shares + loot) * (10 ** decimals);
    }
}

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }
}

contract MolochTokenFactory is CloneFactory {
    address payable public immutable template;

    event MolochTokenCreated(address molochToken, address moloch, string name, string symbol);

    constructor(address payable _template) {
        template = _template;
    }

    function summonMolochToken(
        address _moloch,
        string memory _name,
        string memory _symbol
    ) external returns (address) {
        MolochToken mt = MolochToken(payable(createClone(template)));

        mt.setUp(_moloch, _name, _symbol);

        emit MolochTokenCreated(address(mt), _moloch, _name, _symbol);

        return (address(mt));
    }
}