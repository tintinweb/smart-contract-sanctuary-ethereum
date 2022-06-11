// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract PTX is ERC20, Ownable {

    uint256 public cap;
    mapping(address => bool) public minterList;

    event NewMinter(address minter);
    event MinterRemoved(address minter);

    constructor(uint256 tokenCap_) ERC20("PTX", "PTX") {
        Ownable.init();
        cap = tokenCap_;
    }

    modifier onlyMinter() {
        require(minterList[msg.sender], "PTX: Caller is not minter");
        _;
    }

    function mint(address receiver_, uint256 amount_)
        public
        onlyMinter
        returns (bool)
    {
        require(amount_ > 0, "PTX: Amount can not be zero");
        require(totalSupply() + amount_ <= cap, "PTX: Can not mint more than the token Cap");
        _mint(receiver_, amount_);
        return true;
    }

    function burn(address account_, uint256 amount_) public returns(bool){
        require(amount_ > 0, "PTX: Amount can not be zero");
        require(account_ == msg.sender, "PTX: Only token owner can burn their tokens");
        _burn(account_, amount_);
        return true;
    }

    function addMinter(address minter_) external onlyOwner {
        require(minter_ != address(0), "PTX: Invalid address");
        require(
            !minterList[minter_],
            "PTX: Address already added as minter"
        );
        minterList[minter_] = true;

        emit NewMinter(minter_);
    }

    function removeMinter(address minter_) external onlyOwner {
        require(minter_ != address(0), "PTX: Invalid address");
        require(
            minterList[minter_],
            "PTX: Address does not have minter rights"
        );
        minterList[minter_] = false;

        emit MinterRemoved(minter_);
    }
}