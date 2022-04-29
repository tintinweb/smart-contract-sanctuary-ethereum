pragma solidity ^0.7.6;


contract Box{

    address private owner;
    uint256 private val;
    bool private isInitialized;

    function init(address _owner)public{
        if(isInitialized) revert("Already initialized");
        isInitialized = true;
        owner = _owner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function setVal(uint256 _val) external onlyOwner{
        val = _val;
    }

    function getVal() external view returns(uint256){
        return val;
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getInitialized() external view returns(bool){
        return isInitialized;
    }

    uint256[50] private __gap;

}