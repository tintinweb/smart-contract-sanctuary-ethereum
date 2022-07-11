/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

/***
 * 
 * ███████╗███████╗ ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗     ██╗██╗   ██╗███████╗
 * ██╔════╝██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║     ██║██║   ██║██╔════╝
 * ███████╗█████╗  ██║     ██║   ██║██╔██╗ ██║██║  ██║██║     ██║██║   ██║█████╗  
 * ╚════██║██╔══╝  ██║     ██║   ██║██║╚██╗██║██║  ██║██║     ██║╚██╗ ██╔╝██╔══╝  
 * ███████║███████╗╚██████╗╚██████╔╝██║ ╚████║██████╔╝███████╗██║ ╚████╔╝ ███████╗
 * ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═══╝  ╚══════╝
 *     
 *    
 * https://secondlive.org
                               
* MIT License
* ===========
*
* Copyright (c) 2021 secondlive
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ProxyRegistry is Ownable {

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;
}

contract TokenTransferProxy {

    /* Authentication registry. */
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
        public
        returns (bool)
    {
        require(registry.contracts(msg.sender));
        return ERC20(token).transferFrom(from, to, amount);
    }

}

contract SecondLiveTokenTransferProxy is TokenTransferProxy {

    constructor (ProxyRegistry registryAddr)
        public
    {
        registry = registryAddr;
    }

}