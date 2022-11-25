/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface IPrometheans {
    function currentId() external returns (uint256);

    function mint() external payable;

    function mintTo(address destination) external payable;

    function currentEmber() external view returns (uint256);

    function emberOf(uint256 id) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

contract LFG {
    IPrometheans prometheans;

    address private _owner;

    constructor(address contractAddr_) {
        prometheans = IPrometheans(contractAddr_);

        _owner = msg.sender;
    }

    function updatePrometheans(address contractAddr_) public {
        require(msg.sender == owner(), "NOT OWNER");
        prometheans = IPrometheans(contractAddr_);
    }

    function mint(address _destination, uint256 targetEmberMax)
        external
        payable
    {
        uint256 currentEmber = prometheans.currentEmber();
        require(currentEmber <= targetEmberMax, "Target ember mismatch");

        uint256 currentId = prometheans.currentId();
        uint256 tokenIdForDestination = ++currentId;
        prometheans.mintTo(_destination);

        uint256 emberOfMintedToken = prometheans.emberOf(tokenIdForDestination);

        assert(emberOfMintedToken <= targetEmberMax);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner(), "NOT OWNER");
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }

    function withdraw(address destination, uint256 amount) external {
        require(msg.sender == owner(), "NOT OWNER");

        (bool success, ) = destination.call{value: amount}("");
        require(success, "TRANSFER FAILED");
    }
}