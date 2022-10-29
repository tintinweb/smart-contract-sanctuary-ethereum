/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: GPL-2.0-or-later
// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: wrapAndBuy.sol


pragma solidity ^0.8.13;


interface wETHContract {
    function deposit() external payable;
    function transfer(address, uint) external;
    function withdraw(uint256) external;
    function approve(address, uint) external;
}
interface SwapContract {
    function setUserAddress(address) external;
    function setUserToken(string memory) external;
    function swapExactOutputSingle(uint256, uint256) external;
}

contract EthToOre is ConfirmedOwner{
    wETHContract weth;
    SwapContract swCon;
    
    uint256 private wethBalance;
    address private swapContract;
    uint256 internal linkOut;

    //Set how much LINK you want from the swap contract
    function setLinkOut(uint256 _linkOut) public onlyOwner {
        linkOut = _linkOut;
    }

    constructor(wETHContract _wethAdress, SwapContract _swConAddress)ConfirmedOwner(msg.sender) payable{
        //Enter the address of the WETH contract on deployment
        //0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 - Goerli
        weth = _wethAdress;
        //Enter the address of the swap contract
        //Currently 0x248E43EDC6352FC0593C578035e4F6CCFC89f58a
        swCon = _swConAddress;
        linkOut = 10000000000000000;
    }

    function mintOre(string memory _userToken) external payable {
        swCon.setUserAddress(msg.sender);
        swCon.setUserToken(_userToken);
        weth.deposit{value: msg.value}();
        weth.approve(address(swCon), msg.value);
        swCon.swapExactOutputSingle(linkOut, msg.value);
    }
}