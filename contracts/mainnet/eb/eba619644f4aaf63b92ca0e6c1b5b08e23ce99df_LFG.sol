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
    IPrometheans prometheansIface;

    address private _owner;
    address private _prometheans;

    event Received(address, uint);

    constructor(address contractAddr_) {
        prometheansIface = IPrometheans(contractAddr_);

        _owner = msg.sender;
    }

    function prometheans() public view returns (address) {
        return _prometheans;
    }

    function updatePrometheans(address contractAddr_) public {
        require(msg.sender == owner(), "NOT OWNER");
        _prometheans = contractAddr_;
        prometheansIface = IPrometheans(contractAddr_);
    }

    function mint(address _destination, uint256 targetEmberMax)
        external
        payable
    {
        uint256 currentEmber = prometheansIface.currentEmber();
        require(currentEmber <= targetEmberMax, "Target ember mismatch");

        uint256 currentId = prometheansIface.currentId();
        uint256 tokenIdForDestination = ++currentId;
        prometheansIface.mintTo(_destination);

        uint256 emberOfMintedToken = prometheansIface.emberOf(
            tokenIdForDestination
        );

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

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}