/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

pragma solidity ^0.8.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract bridge is Ownable {

    event BridgeEvent(address recievedFromAddress, uint256 recievedAmount, string sendChchain, string sendToAddress, uint256 suggestedAmount, uint256 minAmount);

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function withdrawAllTo(address payable reciever) external onlyOwner returns(bool) {
        reciever.transfer(address(this).balance);
        return true;
    }

    function withdrawTo(address payable reciever, uint256 amount) external onlyOwner returns(bool) {
        require(amount <= address(this).balance, "Contract balance too low");
        reciever.transfer(amount);
        return true;
    }

    function bridgeTo(string memory sendChain, string memory sendToAddress, uint256 suggestedAmount, uint256 minAmount) external payable returns (bool){
        require(msg.value > 0, "No funds sent.");  
        emit BridgeEvent(msg.sender, msg.value, sendChain, sendToAddress, suggestedAmount, minAmount);
        return true;
    }
}