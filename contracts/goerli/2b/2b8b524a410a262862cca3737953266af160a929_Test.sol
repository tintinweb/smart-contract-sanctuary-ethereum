/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.9;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.9;

contract Test is Ownable {

    mapping(address => uint256) private addressDeposit;

    uint256 public MinimumPresaleAllocation;
    uint256 public MaximumPresaleAllocation;
    uint256 public presaleTotal;
    uint256 public TotalPresaleAllocation;

    bool public PresaleOpen;

    constructor() {
        MinimumPresaleAllocation = 300000000000000; 
        MaximumPresaleAllocation = 300000000000000;
        TotalPresaleAllocation =   1000000000000000;
        PresaleOpen = false;
    }

    function SetMinimumPresaleAllocation(uint256 _MinimumPresaleAllocation) external onlyOwner {
        MinimumPresaleAllocation = _MinimumPresaleAllocation;
    }

    function SetMaximumPresaleAllocation(uint256 _MaximumPresaleAllocation) external onlyOwner {
        MaximumPresaleAllocation = _MaximumPresaleAllocation;
    }

    function SetTotalPresaleAllocation(uint256 _TotalPresaleAllocation) external onlyOwner {
        TotalPresaleAllocation = _TotalPresaleAllocation;
    }

    function SetPresaleOpen(bool _PresaleOpen) external onlyOwner {
        PresaleOpen = _PresaleOpen;
    }

    function getAddressDeposit(address _address) external view returns (uint256) {
        return addressDeposit[_address];
    }

    function depositETH() external payable {

        require (PresaleOpen, "Presale is not open");
      
        require(msg.value >= MinimumPresaleAllocation,
            "Deposit is too low.");
        
        require(msg.value + addressDeposit[msg.sender] <= MaximumPresaleAllocation,
            "Deposit is too high.");

        require(msg.value + presaleTotal <= TotalPresaleAllocation,
            "Deposit exceeds presale limits.");

        
        addressDeposit[msg.sender] += msg.value;
        presaleTotal += msg.value;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}